// MATLAB MEX interface class to access the C++ wrapper class for FFTW.
//  - Damien Loterie (03/2015)


#include "mex.h"
#include "class_handle.hpp"
#include "fftw_wrapper_r2c.cpp"
#include "number_of_cores.cpp"
#include <string>
//#include "gigesource_mex_lib.cpp"


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
        plhs[0] = convertPtr2Mat<FFTW_Wrapper_R2C>(new FFTW_Wrapper_R2C);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");

	// Get the class instance pointer from the second input
	FFTW_Wrapper_R2C *fftw_instance = convertMat2Ptr<FFTW_Wrapper_R2C>(prhs[1]);

	// Delete
	if (!strcmp("delete", cmd)) {
		// Call the shutdown method
		fftw_instance->Shutdown();

		// Destroy the C++ object
		destroyObject<FFTW_Wrapper_R2C>(prhs[1]);

		// Warn if other commands were ignored
		if (nlhs != 0 || nrhs != 2)
			mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
		return;
	}

	// Initialize    
	if (!strcmp("Initialize", cmd)) {
		// Check parameters
		if (nlhs > 1 || nrhs != 4)
			mexErrMsgTxt("Initialize: Unexpected arguments.");

		// Inputs
		size_t width = (size_t)mxGetScalar(prhs[2]);
		size_t height = (size_t)mxGetScalar(prhs[3]);

		// Call the method
		bool res = fftw_instance->Initialize(width, height);

		// Check result
		if (!res)
			mexErrMsgTxt("Initialize: C++ initialization failure.");

		// Return
		return;
	}


	// Get image data  
	if (!strcmp("Transform", cmd)) {
		// Check parameters
		if (nlhs > 2 || nrhs != 3)
			mexErrMsgTxt("Transform: Unexpected arguments.");

		// Check input array
		if (!mxIsNumeric(prhs[2]) || mxIsComplex(prhs[2]))
			mexErrMsgTxt("Transform: Not a real numeric array.");
		if (mxGetNumberOfDimensions(prhs[2]) != 2)
			mexErrMsgTxt("Transform: Wrong array number of dimensions.");
		if (   mxGetN(prhs[2]) != fftw_instance->GetHeight()
			|| mxGetM(prhs[2]) != fftw_instance->GetWidth() )
			mexErrMsgTxt("Transform: Wrong array dimensions.");

		// Transfer frames
		switch (mxGetClassID(prhs[2]))
		{
		case mxINT8_CLASS:
			fftw_instance->SetDataIn((char*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxUINT8_CLASS:
			fftw_instance->SetDataIn((unsigned char*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxINT16_CLASS:
			fftw_instance->SetDataIn((short*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxUINT16_CLASS:
			fftw_instance->SetDataIn((unsigned short*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxINT32_CLASS:
			fftw_instance->SetDataIn((int*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxUINT32_CLASS:
			fftw_instance->SetDataIn((unsigned int*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxSINGLE_CLASS:
			fftw_instance->SetDataIn((float*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		case mxDOUBLE_CLASS:
			fftw_instance->SetDataIn((double*)mxGetData(prhs[2]), mxGetNumberOfElements(prhs[2]));
			break;
		default:
			mexErrMsgTxt("Transform: Unsupported class.");
			return;
			break;
		}

		// Transform
		fftw_instance->TransformForward();

		// Create output array
		plhs[0] = mxCreateNumericMatrix((int)mxGetN(prhs[2]) / 2 + 1,
										(int)mxGetM(prhs[2]),
										FFTW_MATLAB_CLASS,
										mxCOMPLEX);
		Real* pOutputR = (Real*)mxGetData(plhs[0]);
		Real* pOutputI = (Real*)mxGetImagData(plhs[0]);

		// Extract data
		Complex* data_out = fftw_instance->GetDataOutPtr();
		for (size_t i = 0; i < mxGetNumberOfElements(plhs[0]); i++)
		{
			pOutputR[i] = data_out[i].real();
			pOutputI[i] = data_out[i].imag();
		}
			

		// Return
		return;
	}


    // Got here, so command not recognized
    mexErrMsgTxt("Command not recognized.");
}
