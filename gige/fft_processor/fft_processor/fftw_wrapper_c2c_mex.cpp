// MATLAB MEX interface class to access the C++ wrapper class for FFTW.
//  - Damien Loterie (03/2015)


#include "mex.h"
#include "class_handle.hpp"
#include "fftw_wrapper_c2c.cpp"
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
		plhs[0] = convertPtr2Mat<FFTW_Wrapper_C2C>(new FFTW_Wrapper_C2C);
		return;
	}

	// Check there is a second input, which should be the class instance handle
	if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");

	// Get the class instance pointer from the second input
	FFTW_Wrapper_C2C *fftw_instance = convertMat2Ptr<FFTW_Wrapper_C2C>(prhs[1]);

	// Delete
	if (!strcmp("delete", cmd)) {
		// Call the shutdown method
		fftw_instance->Shutdown();

		// Destroy the C++ object
		destroyObject<FFTW_Wrapper_C2C>(prhs[1]);

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
		if (!mxIsNumeric(prhs[2]) || !mxIsComplex(prhs[2]) || !(mxGetClassID(prhs[2]) == FFTW_MATLAB_CLASS))
			mexErrMsgTxt("Transform: Not a complex numeric array of the right type.");
		if (mxGetNumberOfDimensions(prhs[2]) != 2)
			mexErrMsgTxt("Transform: Wrong array number of dimensions.");
		if (mxGetN(prhs[2]) != fftw_instance->GetHeight()
			|| mxGetM(prhs[2]) != fftw_instance->GetWidth())
			mexErrMsgTxt("Transform: Wrong array dimensions.");

		// Transfer frame
		Complex* data_in = fftw_instance->GetDataInPtr();
		const Real* pInputR = (const Real*)mxGetData(prhs[2]);
		const Real* pInputI = (const Real*)mxGetImagData(prhs[2]);
		for (size_t i = 0; i < mxGetNumberOfElements(prhs[2]); i++)
		{
			data_in[i] = Complex(pInputR[i], pInputI[i]);
		}

		// Transform
		fftw_instance->TransformForward();

		// Create output array
		plhs[0] = mxCreateNumericMatrix((int)mxGetN(prhs[2]),
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


	// Gerchberg-Saxton
	if (!strcmp("GerchbergSaxton", cmd)) {
		//////////////////////
		// INPUT PROCESSING //
		//////////////////////
		// Check parameters
		if (nlhs > 2 || nrhs != 5)
			mexErrMsgTxt("GerchbergSaxton: Unexpected arguments.");

		// Check input array
		if (!mxIsNumeric(prhs[2]) || !mxIsComplex(prhs[2]) || !(mxGetClassID(prhs[2]) == FFTW_MATLAB_CLASS))
			mexErrMsgTxt("GerchbergSaxton: Not a complex numeric array of the right type.");
		if (mxGetNumberOfDimensions(prhs[2]) != 2)
			mexErrMsgTxt("GerchbergSaxton: Wrong array number of dimensions.");
		if (!mxIsInt32(prhs[3]) || mxIsComplex(prhs[3]))
			mexErrMsgTxt("GerchbergSaxton: Not a uint64 index array.");
		if (mxGetNumberOfElements(prhs[2]) != mxGetNumberOfElements(prhs[3]))
			mexErrMsgTxt("GerchbergSaxton: Index and data array mismatch.");

		// Get pointers
		Complex* data_out = fftw_instance->GetDataOutPtr();
		Complex* data_in  = fftw_instance->GetDataInPtr();
		const int* pInd = (const int*)mxGetData(prhs[3]);
		const Real* pInputR = (const Real*)mxGetData(prhs[2]);
		const Real* pInputI = (const Real*)mxGetImagData(prhs[2]);
		size_t N_ind  = (size_t)mxGetNumberOfElements(prhs[3]);
		size_t N_full = fftw_instance->GetSizeIn();
		size_t N_iter = (size_t)mxGetScalar(prhs[4]);

		///////////////////////
		// INITIAL ITERATION //
		///////////////////////
		// Copy initial FFT data
		SecureZeroMemory(data_out, fftw_instance->GetSizeOut()*sizeof(*data_out));
		for (size_t i = 0; i < N_ind; i++)
		{
			if (pInd[i] < N_full)
			{
				data_out[pInd[i]] = Complex(pInputR[i], pInputI[i]);
			}
			else
			{
				mexErrMsgTxt("GerchbergSaxton: Index out of bounds.");
				return;
			}
		}

		// Transform
		fftw_instance->TransformBackward();

		// Get maximum norm
		Real max_norm = 0;
		for (size_t i = 0; i < N_full; i++)
		{
			Real current_norm = norm(data_in[i]);
			if (current_norm > max_norm)
				max_norm = current_norm;
		}
		
		// Set normalization factor
		Real norm_factor = max_norm / ((double)N_full);

		// Normalize
		for (size_t i = 0; i < N_full; i++)
		{
			Real temp_norm = norm(data_in[i]);
			if (temp_norm != 0)
			{
				data_in[i] = data_in[i] * (norm_factor / temp_norm);
			}
			else
			{
				data_in[i] = norm_factor;
			}
		}

		//////////////////////
		// EXTRA ITERATIONS //
		//////////////////////
		for (size_t k = 1; k < N_iter; k++)
		{ 
			// Transform
			fftw_instance->TransformForward();

			// Copy FFT data
			for (size_t i = 0; i < N_ind; i++)
				data_out[pInd[i]] = Complex(pInputR[i], pInputI[i]);

			// Transform
			fftw_instance->TransformBackward();

			// Normalize
			for (size_t i = 0; i < N_full; i++)
				data_in[i] = data_in[i] * (norm_factor / norm(data_in[i]));
		}

		////////////
		// OUTPUT //
		////////////
		// Create output array
		plhs[0] = mxCreateNumericMatrix((int)fftw_instance->GetHeight(),
										(int)fftw_instance->GetWidth(),
										FFTW_MATLAB_CLASS,
										mxCOMPLEX);
		Real* pOutputR = (Real*)mxGetData(plhs[0]);
		Real* pOutputI = (Real*)mxGetImagData(plhs[0]);

		// Extract data
		for (size_t i = 0; i < N_full; i++)
		{
			pOutputR[i] = data_in[i].real();
			pOutputI[i] = data_in[i].imag();
		}

		// Return
		return;
	}


	// Got here, so command not recognized
	mexErrMsgTxt("Command not recognized.");
}
