// MATLAB MEX interface class for GigE acquisition with the Pleora SDK
// Based on class_handle.hpp by Oliver Woodford
//  - Damien Loterie (11/2014)



#include "mex.h"
#include "class_handle.hpp"
#include "gigesource_mex_lib.cpp"

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
        plhs[0] = convertPtr2Mat<GigE_Source>(new GigE_Source);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");
    
	// Get the class instance pointer from the second input
    GigE_Source *GigE_instance = convertMat2Ptr<GigE_Source>(prhs[1]);
	
    // Delete
    if (!strcmp("delete", cmd)) {
		// Call the shutdown method
		GigE_instance->Shutdown();
	
        // Destroy the C++ object
        destroyObject<GigE_Source>(prhs[1]);
		
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    }
    
    // Initialize    
    if (!strcmp("Initialize", cmd)) {
        // Check parameters
        if (nlhs>1 || nrhs != 3)
            mexErrMsgTxt("Initialize: Unexpected arguments.");

        // Call the method
        PvResult res = GigE_instance->Initialize(GetPvString(prhs[2]));
		
		// Check result
		if (!res.IsOK())
			mexErrMsgTxt(GetPvString(res));
		
		// Return
        return;
    }

    // Get all parameters    
    if (!strcmp("GetAll", cmd)) {
        // Check parameters
        if (nlhs!=1 || nrhs != 2)
            mexErrMsgTxt("GetAll: Unexpected arguments.");

        // Call the method
        plhs[0] = GetMxStruct(GigE_instance->lDeviceParams);
		
		// Return
        return;
    }

	// Start acquisition
	if (!strcmp("Start", cmd)) {
		// Check parameters
		if (nlhs != 0 || nrhs != 2)
			mexErrMsgTxt("Start: Unexpected arguments.");

		// Process any errors
		PvResult res = GigE_instance->Start();

		// Check result
		if (!res.IsOK())
			mexErrMsgTxt(GetPvString(res));

		// Return
		return;
	}

	// Stop acquisition
	if (!strcmp("Stop", cmd)) {
		// Check parameters
		if (nlhs != 0 || nrhs != 2)
			mexErrMsgTxt("Stop: Unexpected arguments.");

		// Process any errors
		PvResult res = GigE_instance->Stop();

		// Check result
		if (!res.IsOK())
			mexErrMsgTxt(GetPvString(res));

		// Return
		return;
	}

	
    // Get one parameter  
    if (!strcmp("Get", cmd)) {
        // Check parameters
        if (nlhs!=1 || nrhs != 3)
            mexErrMsgTxt("Get: Unexpected arguments.");

		// Get parameter
		PvGenParameter *PvPar = GigE_instance->lDeviceParams->Get(GetPvString(prhs[2]));

		// Check result
		if (PvPar == NULL)
			mexErrMsgTxt("Get: Parameter not found.");
		
        // Convert to MATLAB
        plhs[0] = GetMxArrayFromPvParValue(PvPar);
		
		// Return
        return;
    }
	
    // Set one parameter  
    if (!strcmp("Set", cmd)) {
        // Check parameters
        if (nlhs!=0 || nrhs != 4)
            mexErrMsgTxt("Set: Unexpected arguments.");

		// Get parameter
		PvGenParameter *PvPar = GigE_instance->lDeviceParams->Get(GetPvString(prhs[2]));

		// Check result
		if (PvPar == NULL)
			mexErrMsgTxt("Set: Parameter not found.");
		
        // Call a separate method for setting
		SetPvParValueFromMxArray(PvPar, mxDuplicateArray(prhs[3]));
		
		// Return
        return;
    }
	
	// Get number of available images 
	if (!strcmp("GetNumberOfImages", cmd)) {
		// Check parameters
		if (nlhs != 1 || nrhs != 2)
			mexErrMsgTxt("GetNumberOfImages: Unexpected arguments.");

		// Get number
		plhs[0] = mxCreateDoubleScalar((double)GigE_instance->GetNumberOfAvailableImages());

		// Return
		return;
	}

    // Get image data  
    if (!strcmp("GetLastImage", cmd)) {
        // Check parameters
        if (nlhs!=1 || nrhs != 2)
            mexErrMsgTxt("GetLastImage: Unexpected arguments.");

		// Try to pop an image
		std::unique_ptr<PvBuffer> pBuffer = GigE_instance->GetImage();

		// Check if pop was successful
		if (!pBuffer)
			mexErrMsgTxt("GetLastImage: no available image.");

		// Go until the last image
		std::unique_ptr<PvBuffer> pBufferNew;
		while (pBufferNew = GigE_instance->GetImage())
			pBuffer.reset(pBufferNew.release());

		// Get image specific buffer interface
		PvImage *lImage = pBuffer->GetImage();

		// Read image dimensions
		uint32_t ImageWidth = lImage->GetWidth();
		uint32_t ImageHeight = lImage->GetHeight();
		uint32_t ImageBpp = lImage->GetBitsPerPixel();
		
		// Transfer to a MATLAB array (and transpose)
		switch (ImageBpp)
		{
		case 8:
			plhs[0] = mxCreateNumericMatrix((int)ImageHeight, (int)ImageWidth, mxUINT8_CLASS, mxREAL);
			transpose((char*)mxGetData(plhs[0]), lImage->GetDataPointer(), ImageWidth, ImageHeight);
			break;
		case 16:
			plhs[0] = mxCreateNumericMatrix((int)ImageHeight, (int)ImageWidth, mxUINT16_CLASS, mxREAL);
			transpose((short*)mxGetData(plhs[0]), lImage->GetDataPointer(), ImageWidth, ImageHeight);
			break;
		default:
			pBuffer.reset();
			mexErrMsgTxt("GetSingleImage: Unsupported bit depth.");
			return;
			break;
		}

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
		if (NumberOfFrames > GigE_instance->GetNumberOfAvailableImages())
			mexErrMsgTxt("GetImages: The number of images requested exceeds the number of available images.");

		// Pop the first image
		std::unique_ptr<PvBuffer> pBuffer = GigE_instance->GetImage();

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
				transfer_many(&pMat[ImageWidth*ImageHeight], &pTime[1], GigE_instance, ImageWidth, ImageHeight, NumberOfFrames-1);
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
				transfer_many(&pMat[ImageWidth*ImageHeight], &pTime[1], GigE_instance, ImageWidth, ImageHeight, NumberOfFrames - 1);
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

	// Flush all data
	if (!strcmp("FlushImages", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("FlushImages: Unexpected arguments.");

		// Flush
		PvResult res = GigE_instance->FlushImages();

		// Check result
		if (!res.IsOK())
			mexErrMsgTxt(GetPvString(res));

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
		DWORD res = GigE_instance->WaitImages(NumberOfFrames, (DWORD)(timeoutSeconds*1000));

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

	// Get number of buffer thread errors
	if (!strcmp("GetNumberOfErrors", cmd)) {
		// Check parameters
		if (nlhs != 1 || nrhs != 2)
			mexErrMsgTxt("GetNumberOfErrors: Unexpected arguments.");

		// Get number
		plhs[0] = mxCreateDoubleScalar((double)GigE_instance->GetNumberOfErrors());

		// Return
		return;
	}


	// Get image data  
	if (!strcmp("GetErrors", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("GetErrors: Unexpected arguments.");

		// Get number
		size_t NumberOfErrors = GigE_instance->GetNumberOfErrors();

		// Create MATLAB array that will contain the error strings
		mxArray *mxStrArr = mxCreateCellMatrix((mwSize)NumberOfErrors, 1);

		// Gather all the errors
		for (size_t i = 0; i < NumberOfErrors; i++)
		{
			// Pop error
			std::unique_ptr<PvResult> pRes = GigE_instance->GetError();

			// Check if pop was successful
			if (!pRes)
				mexErrMsgTxt("GetErrors: One of the errors could not be retrieved. Due to this problem, some of the errors were lost.");

			// Make string
			mxArray *mxStr = mxCreateString(GetPvString(*pRes));

			// Save string to cell array
			mxSetCell(mxStrArr, (mwIndex)i, mxStr);

			// Clear
			pRes.reset();
		}

		// Return
		plhs[0] = mxStrArr;
		return;
	}


	/// -------------------------------- JWJS -----------------------------------
	// Get number of buffer thread errors
	if (!strcmp("GetDeviceInfo", cmd)) 
	{
		// Check parameters
		if (nlhs > 1 || nrhs != 2)
			mexErrMsgTxt("GetDeviceInfo: Unexpected arguments.");

		// Get number
		//size_t NumberOfErrors = GigE_instance->GetNumberOfErrors();

		/// Create MATLAB array that will contain the device information strings.
		/// We want IP, model, serial and MAC address.
		size_t numberOfDeviceProperties = 4;
		mxArray *mxStrArr = mxCreateCellMatrix((mwSize)numberOfDeviceProperties, 1);

		/// Create the strings of the device info and save it to the cell array
		mxSetCell(mxStrArr, (mwIndex)0, mxCreateString(GigE_instance->GetDeviceIP()));
		mxSetCell(mxStrArr, (mwIndex)1, mxCreateString(GigE_instance->GetDeviceModelName()));
		mxSetCell(mxStrArr, (mwIndex)2, mxCreateString(GigE_instance->GetDeviceSerialNumber()));
		mxSetCell(mxStrArr, (mwIndex)3, mxCreateString(GigE_instance->GetDeviceMACAddress()));

		/// Return the data.
		plhs[0] = mxStrArr;

		return;
	}
	/// -------------------------------------


	/// -------------------------------- JWJS --------------------------------------
	/// Display available devices and make a selection.
	if (!strcmp("SelectDevice", cmd)) 
	{

		// Check parameters
		if (nlhs != 0 || nrhs != 2)
			mexErrMsgTxt("SelectDevice: Unexpected arguments.");

		GigE_instance->lPvSystem->Find();

		//// Detect, select device.
		vector<const PvDeviceInfo *> lDIVector;
		for (uint32_t i = 0; i < GigE_instance->lPvSystem->GetInterfaceCount(); i++)
		{
			const PvInterface *lInterface = dynamic_cast<const PvInterface *>(GigE_instance->lPvSystem->GetInterface(i));
			if (lInterface != NULL)
			{
				//mexPrintf("Interface: %s\n", lInterface->GetDisplayID().GetAscii());
				for (uint32_t j = 0; j < lInterface->GetDeviceCount(); j++)
				{
					const PvDeviceInfo *lDI = dynamic_cast<const PvDeviceInfo *>(lInterface->GetDeviceInfo(j));
					if (lDI != NULL)
					{
						lDIVector.push_back(lDI);
						mexPrintf("[%d]\t %s \n", lDIVector.size() - 1, lDI->GetDisplayID().GetAscii());
					}
				}
			}
		}

		if (lDIVector.size() == 0)
		{
			mexPrintf("No device found!\n");
		}

		mexPrintf("[%d] to abort\n", lDIVector.size());
		mexPrintf("[%d] to search again\n\n", (lDIVector.size() + 1));
		
		/// Get input from the user via the Matlab console.
		mxArray *new_number, *str;
		size_t lIndex = -1;
		
		str = mxCreateString("Enter your action or device selection: ");
		mexCallMATLAB(1, &new_number, 1, &str, "input");
		lIndex = mxGetScalar(new_number);
		//mexPrintf("You entered: %d\n", lIndex);
		mxDestroyArray(new_number);
		mxDestroyArray(str);


		// Read device selection, optional new IP address.
		if (lIndex == lDIVector.size())
		{
			// We abort the selection process.
			return;
		}
		else if (lIndex < lDIVector.size())
		{
			// The device is selected
			///lSelectedDI = lDIVector[lIndex];
			GigE_instance->AssignPvDeviceInfo(lDIVector[lIndex]);
			return;
		}
		
		
		/// Should not make it here if the above conditions are met.
		return;
	}
	/// --------------------------------------





    // Got here, so command not recognized
    mexErrMsgTxt("Command not recognized.");
}
