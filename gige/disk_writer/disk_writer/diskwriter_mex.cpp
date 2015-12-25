// MATLAB MEX interface class for disk writing of gigesource output
// Based on class_handle.hpp by Oliver Woodford
//  - Damien Loterie (03/2015)


#include "mex.h"
#include "class_handle.hpp"
#include "diskwriter.cpp"
#include "gigesource_mex_lib.cpp"
#include "gigesource.h"



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
    // Get the command string
    char cmd[64];
	if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd)))
		mexErrMsgTxt("First input should be a command string less than 64 characters long.");
        
    // New
    if (!strcmp("new", cmd)) {
        // Check parameters
        if (nlhs != 1)
            mexErrMsgTxt("New: One output expected.");
			
        // Return a handle to a new C++ instance
        plhs[0] = convertPtr2Mat<DiskWriter>(new DiskWriter);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");
    
	// Get the class instance pointer from the second input
    DiskWriter *dw_instance = convertMat2Ptr<DiskWriter>(prhs[1]);
	
    // Delete
    if (!strcmp("delete", cmd)) {
		// Call the shutdown method
		dw_instance->Shutdown();
	
        // Destroy the C++ object
        destroyObject<DiskWriter>(prhs[1]);
		
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    }
    
    // Initialize    
    if (!strcmp("Initialize", cmd)) {
        // Check parameters
        if (nlhs>1 || nrhs != 5)
            mexErrMsgTxt("Initialize: Unexpected arguments.");
		if (!mxIsChar(prhs[2]) || !mxIsLogicalScalar(prhs[4]))
			mexErrMsgTxt("Initialize: Unexpected arguments.");

		// Inputs
		LPCTSTR      file_path    = mxArrayToString(prhs[2]);
		bool         pass_through = mxIsLogicalScalarTrue(prhs[4]);
		
		IImageQueue* source;
		if (mxIsClass(prhs[3], "gigesource")) {
			source = (IImageQueue*)convertMat2Ptr<GigE_Source>(mxGetProperty(prhs[3], 0, "objectHandle"));
		} else {
			mexErrMsgTxt("Initialize: Unsupported source class.");
		}
		
        // Call the method
		bool res = dw_instance->Initialize(file_path, source, pass_through);
		
		// Check result
		if (!res)
			mexErrMsgTxt("Initialize: C++ initialization failure.");
		
		// Return
        return;
    }

	
	// Get number of available images 
	if (!strcmp("GetNumberOfImages", cmd)) {
		// Check parameters
		if (nlhs != 1 || nrhs != 2)
			mexErrMsgTxt("GetNumberOfImages: Unexpected arguments.");

		// Get number
		plhs[0] = mxCreateDoubleScalar((double)dw_instance->GetNumberOfAvailableImages());

		// Return
		return;
	}

	// Get image data  
	if (!strcmp("GetImages", cmd)) {
		// Check parameters
		if (nlhs > 2 || nrhs != 3 || mxGetNumberOfElements(prhs[2])!=1)
			mexErrMsgTxt("GetImages: Unexpected arguments.");

		// Read input (number of frames)
		size_t NumberOfFrames = (size_t)mxGetScalar(prhs[2]);

		// Check if there are that many frames available
		if (NumberOfFrames > dw_instance->GetNumberOfAvailableImages())
			mexErrMsgTxt("GetImages: The number of images requested exceeds the number of available images.");

		// Pop the first image
		std::unique_ptr<PvBuffer> pBuffer = dw_instance->GetImage();

		// Check if pop was successful
		if (!pBuffer)
			mexErrMsgTxt("GetImages: The first image could not be retrieved.");

		// Get image specific buffer interface
		PvImage *lImage = pBuffer->GetImage();

		// Read image dimensions
		uint32_t ImageWidth = lImage->GetWidth();
        uint32_t ImageHeight = lImage->GetHeight();
		uint32_t ImageBpp = lImage->GetBitsPerPixel();

		// Prepare dimensions of the MATLAB frames array
		mwSize ndims = 4;
		mwSize dims[4]{ImageHeight, ImageWidth, 1, (mwSize)NumberOfFrames};

		// Prepare MATLAB time array
		mxArray*  mxTime = mxCreateNumericMatrix((int)NumberOfFrames, 1, mxUINT64_CLASS, mxREAL);
		uint64_t*  pTime = (uint64_t*)mxGetData(mxTime);

		// Transfer frames
		switch (ImageBpp)
		{
		case 8:
			{
				// Create a MATLAB array
				plhs[0] = mxCreateNumericArray(ndims, dims, mxUINT8_CLASS, mxREAL);

				// Transfer first frame
				char* pMat = (char*)mxGetData(plhs[0]);
				transpose(pMat, lImage->GetDataPointer(), ImageWidth, ImageHeight);
				pTime[0] = pBuffer->GetTimestamp();
				pBuffer.reset();

				// Transfer the other frames
				transfer_many(&pMat[ImageWidth*ImageHeight], &pTime[1], dw_instance, ImageWidth, ImageHeight, NumberOfFrames-1);
			}
			break;
		case 16:
			{
				// Create array
				plhs[0] = mxCreateNumericArray(ndims, dims, mxUINT16_CLASS, mxREAL);

				// Transfer first frame
				short* pMat = (short*)mxGetData(plhs[0]);
				transpose(pMat, lImage->GetDataPointer(), ImageWidth, ImageHeight);
				pTime[0] = pBuffer->GetTimestamp();
				pBuffer.reset();

				// Transfer the other frames
				transfer_many(&pMat[ImageWidth*ImageHeight], &pTime[1], dw_instance, ImageWidth, ImageHeight, NumberOfFrames - 1);
			}
			break;
		default:
			pBuffer.reset();
			mexErrMsgTxt("GetImages: Unsupported bit depth.");
			return;
			break;
		}

		// Calculate timestamps
		if (nlhs >= 2)
		{
			plhs[1] = mxTime;
		}

		// Return
		return;
	}

	// Wait for a certain number of images
	if (!strcmp("WaitImages", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 4 || mxGetNumberOfElements(prhs[2]) != 1 || mxGetNumberOfElements(prhs[3]) != 1)
			mexErrMsgTxt("WaitImages: Unexpected arguments.");

		// Read inputs
		size_t  NumberOfFrames = (size_t)mxGetScalar(prhs[2]);
		double  timeoutSeconds = (double)mxGetScalar(prhs[3]);

		// Wait
		DWORD res = dw_instance->WaitImages(NumberOfFrames, (DWORD)(timeoutSeconds*1000));

		// Check result
		if (res == WAIT_TIMEOUT)
		{
			mexErrMsgTxt("WaitImages: Timeout.");
		}
		else if (res == WAIT_FAILED)
		{
			mexErrMsgTxt("WaitImages: Failure.");
		}
			
		// Return
		return;
	}

	// Flush all data
	if (!strcmp("FlushImages", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("FlushImages: Unexpected arguments.");

		// Flush
		bool res = dw_instance->FlushImages();

		// Check result
		if (!res)
			mexErrMsgTxt("FlushImages: Failure.");

		// Return
		return;
	}

	// Get number of buffer thread errors
	if (!strcmp("GetNumberOfErrors", cmd)) {
		// Check parameters
		if (nlhs != 1 || nrhs != 2)
			mexErrMsgTxt("GetNumberOfErrors: Unexpected arguments.");

		// Get number
		plhs[0] = mxCreateDoubleScalar((double)dw_instance->GetNumberOfErrors());

		// Return
		return;
	}


	// Get image data  
	if (!strcmp("GetErrors", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("GetErrors: Unexpected arguments.");

		// Get number
		size_t NumberOfErrors = dw_instance->GetNumberOfErrors();

		// Create MATLAB array that will contain the error strings
		mxArray *mxStrArr = mxCreateCellMatrix((mwSize)NumberOfErrors, 1);

		// Gather all the errors
		for (size_t i = 0; i < NumberOfErrors; i++)
		{
			// Pop error
			std::unique_ptr<std::string> pRes = dw_instance->GetError();

			// Check if pop was successful
			if (!pRes)
				mexErrMsgTxt("GetErrors: One of the errors could not be retrieved. Due to this problem, some of the errors were lost.");

			// Make string
			mxArray *mxStr = mxCreateString(pRes->c_str());

			// Save string to cell array
			mxSetCell(mxStrArr, (mwIndex)i, mxStr);

			// Clear
			pRes.reset();
		}

		// Return
		plhs[0] = mxStrArr;
		return;
	}

    // Got here, so command not recognized
    mexErrMsgTxt("Command not recognized.");
}
