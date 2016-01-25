// MATLAB MEX interface class for FFT transformation of gigesource output
// Based on class_handle.hpp by Oliver Woodford
//  - Damien Loterie (03/2015)


#include "mex.h"
#include "class_handle.hpp"
#include "number_of_cores.cpp"
#include "fftw_wrapper_r2c.cpp"
#include "fftprocessor.cpp"
#include "gigesource_mex_lib.cpp"
#include "diskwriter.cpp"
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
        plhs[0] = convertPtr2Mat<FFTProcessor>(new FFTProcessor);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");
    
	// Get the class instance pointer from the second input
    FFTProcessor *proc_instance = convertMat2Ptr<FFTProcessor>(prhs[1]);
	
    // Delete
    if (!strcmp("delete", cmd)) {
		// Call the shutdown method
		proc_instance->Shutdown();
	
        // Destroy the C++ object
        destroyObject<FFTProcessor>(prhs[1]);
		
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    }
    
    // Initialize    
    if (!strcmp("Initialize", cmd)) {
        // Check parameters
        if (nlhs>1 || nrhs != 6)
            mexErrMsgTxt("Initialize: Unexpected arguments.");

		// Inputs
		size_t width = mxGetScalar(prhs[2]);
		size_t height = mxGetScalar(prhs[3]);
		
		IImageQueue* source;
		if (mxIsClass(prhs[4], "gigesource")) {
			source = (IImageQueue*)convertMat2Ptr<GigE_Source>(mxGetProperty(prhs[4],0,"objectHandle"));
		} else if (mxIsClass(prhs[4], "diskwriter")) {
			source = (IImageQueue*)convertMat2Ptr<DiskWriter>(mxGetProperty(prhs[4],0,"objectHandle"));
		} else {
			mexErrMsgTxt("Initialize: Unsupported source class.");
		}
		
		vector<int> indices;
		if (!mxIsInt32(prhs[5]))
			mexErrMsgTxt("Initialize: indices must be of type 'int32'.");
		int*   pIndData = (int*)mxGetData(prhs[5]);
		size_t indices_numel = mxGetNumberOfElements(prhs[5]);
		indices.reserve(indices_numel);
		for (size_t i = 0; i < indices_numel; i++)
		{
			indices.push_back(pIndData[i]);
		}

        // Call the initialization routine
		if (!proc_instance->Initialize(source, width, height, indices))
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
		plhs[0] = mxCreateDoubleScalar((double)proc_instance->GetNumberOfAvailableImages());

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
		if (NumberOfFrames > proc_instance->GetNumberOfAvailableImages())
			mexErrMsgTxt("GetImages: The number of images requested exceeds the number of available images.");

		// Pop the first image
		unique_ptr<FFTExtract> vec = proc_instance->GetImage();

		// Check if pop was successful
		if (!vec)
			mexErrMsgTxt("GetImages: The first image could not be retrieved.");

		// Create MATLAB data array
		mwSize NumberOfElements = vec->coefficients.size();
		#ifdef FFTW_PRECISION_FLOAT
			plhs[0] = mxCreateNumericMatrix(NumberOfElements, NumberOfFrames, mxSINGLE_CLASS, mxCOMPLEX);
		#else
			plhs[0] = mxCreateNumericMatrix(NumberOfElements, NumberOfFrames, mxDOUBLE_CLASS, mxCOMPLEX);
		#endif
		Real* data_real = (Real*)mxGetData(plhs[0]);
		Real* data_imag = (Real*)mxGetImagData(plhs[0]);

		// Create MATLAB time array
		mxArray*  mxTime = mxCreateNumericMatrix((int)NumberOfFrames, 1, mxUINT64_CLASS, mxREAL);
		uint64_t*  pTime = (uint64_t*)mxGetData(mxTime);

		// Transfer first frame
		for (size_t i = 0; i < NumberOfElements; i++)
		{
			data_real[i] = vec->coefficients.at(i).real();
			data_imag[i] = vec->coefficients.at(i).imag();
		}
		pTime[0] = vec->timestamp;
		vec.reset();

		// Transfer the other frames
		for (size_t n = 1; n < NumberOfFrames; n++)
		{
			// Pop the next image
			vec = proc_instance->GetImage();

			// Check if pop was successful
			if (!vec)
				mexErrMsgTxt("GetImages: An image could not be retrieved. Some of the data was lost.");
			if (vec->coefficients.size()!=NumberOfElements)
				mexErrMsgTxt("GetImages: Not all the images have the right size. Some of the data was lost.");

			// Copy to MATLAB
			for (size_t i = 0; i < NumberOfElements; i++)
			{
				data_real[n*NumberOfElements + i] = vec->coefficients.at(i).real();
				data_imag[n*NumberOfElements + i] = vec->coefficients.at(i).imag();
			}
			pTime[n] = vec->timestamp;

			// Clear
			vec.reset();
		}

		// Return timestamps if needed
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
		DWORD res = proc_instance->WaitImages(NumberOfFrames, (DWORD)(timeoutSeconds*1000));

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
		bool res = proc_instance->FlushImages();

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
		plhs[0] = mxCreateDoubleScalar((double)proc_instance->GetNumberOfErrors());

		// Return
		return;
	}


	// Get image data  
	if (!strcmp("GetErrors", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("GetErrors: Unexpected arguments.");

		// Get number
		size_t NumberOfErrors = proc_instance->GetNumberOfErrors();

		// Create MATLAB array that will contain the error strings
		mxArray *mxStrArr = mxCreateCellMatrix((mwSize)NumberOfErrors, 1);

		// Gather all the errors
		for (size_t i = 0; i < NumberOfErrors; i++)
		{
			// Pop error
			std::unique_ptr<std::string> pRes = proc_instance->GetError();

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
