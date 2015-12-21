// Fast uint8 angle routines
// See also Girones, Julia and Puig (2013)
//  - Damien Loterie (03/2014)

#include "mex.h"
#include <math.h>

#define PI 3.141592653589793
#define uint32_t unsigned int

float fast_atan2( float y, float x )
{
	static const uint32_t sign_mask = 0x80000000;
	static const float b = 0.596227f;
	
	// Extract the sign bits
	uint32_t ux_s = sign_mask & (uint32_t &)x;
	uint32_t uy_s = sign_mask & (uint32_t &)y;
	
	// Determine the quadrant offset
	float q = (float)( (~ux_s & uy_s ) >> 29 | ux_s >> 30 );
	
	// Calculate the arctangent in the first quadrant
	float bxy_a = ::fabs( b * x * y );
	float num = bxy_a + y * y;
	float atan_1q = num / ( x * x + bxy_a + num );
	
	// Translate it to the proper quadrant
	uint32_t uatan_2q = (ux_s ^ uy_s) | (uint32_t &)atan_1q;
	return q + (float &)uatan_2q;
}

	

void convert(float *x, float *y, unsigned char *v, int n)
{
	// int* w = new int[n];
	
	#pragma loop(hint_parallel(8))
	#pragma loop(ivdep) 
	for (int i = 0; i<n; i++)
	{
		// Fast approximate formula; 300Mops, 7.4% errors.
		v[i] = (unsigned char)(64*fast_atan2(y[i], x[i])+0.5);
		
		// Slower more accurate formula: 100Mops, 0.0006% errors.
		//float temp = (256/(2*PI))*atan2f(y[i], x[i])+0.5;
		//if (temp < 0) temp += 256;
		//v[i] = (unsigned char)temp;
		
		//v[i] = 64*fast_atan2(y[i], x[i]);
		//w[i] = (int)((256/(2*PI))*atan2f(y[i], x[i])+0.5);
	}
	
	// unsigned char* wc = (unsigned char*)w;
	// #pragma loop(hint_parallel(4))
	// #pragma loop(ivdep) 
	// for (int i = 0; i<n; i++)
	// {
		// //v[i] = (unsigned char)(64*fast_atan2(y[i], x[i])+0.5);
		// //v[i] = (unsigned char)((256/(2*PI))*atan2f(y[i], x[i])+0.5);
		// v[i] = wc[4*i+3];
	// }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
	// Check there is an input
	if (nrhs!=1)
	{
		mexErrMsgTxt("Input should be an array.");
	}

	// Check complexity
	if (!mxIsComplex(prhs[0]))
		mexErrMsgTxt("Array is not complex.");
	
	// Create output array
	if (nlhs != 1)
	{
		mexErrMsgTxt("One output argument expected.");
	}
	mxArray *mArr = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[0]),
	                                     mxGetDimensions(prhs[0]), 
                                         mxUINT8_CLASS,
										 mxREAL);
	size_t n = mxGetNumberOfElements(prhs[0]); 

	// Class cases
	if (mxIsSingle(prhs[0])) {
		convert((float*)mxGetData(prhs[0]),
			    (float*)mxGetImagData(prhs[0]),
			    (unsigned char*)mxGetData(mArr),
			    (int)n);
	} else {
		mexErrMsgTxt("Unexpected type.");
	}
	
	// Return array
	plhs[0] = mArr;	
	return;
}