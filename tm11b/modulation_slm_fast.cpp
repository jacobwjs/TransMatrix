// Fast uint8 addition with overflow
//  - Damien Loterie (03/2014)

#include "windows.h"
#include "mex.h"
#include <math.h>

#define PI 3.141592653589793
#define uint32_t unsigned int



void add(unsigned char *x, unsigned char *y, unsigned char *v, int n)
{
	#pragma loop(hint_parallel(8))
	#pragma loop(ivdep) 
	for (int i = 0; i<n; i++)
	{
        // Speed: 2.3Gbyte/s
		v[i] = x[i]+y[i];
	}
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
	// Check if there is an input
	if (nrhs!=4)
	{
		mexErrMsgTxt("Input should be four parameters.");
	}
    
    // Check types
	if (!mxIsInt32(prhs[0]) || 
		!mxIsInt32(prhs[1]) ||
		!mxIsInt32(prhs[2]) ||
		!mxIsInt32(prhs[3]))
    {
        mexErrMsgTxt("Parameters should be of type int.");
    }
    
    // Check sizes
	if (mxGetNumberOfElements(prhs[0]) != 1 || 
		mxGetNumberOfElements(prhs[1]) != 1 )
    {
        mexErrMsgTxt("The first two parameters should not be arrays.");
    }
	if (mxGetNumberOfElements(prhs[2]) != mxGetNumberOfElements(prhs[3]))
	{
		mexErrMsgTxt("The last two parameters should have the same size.");
	}
    
    // Check output
    if (nlhs > 2)
	{
		mexErrMsgTxt("Only one output argument expected.");
	}
    
	// Read input
	int  X  = (int)mxGetScalar(prhs[0]);
	int  Y  = (int)mxGetScalar(prhs[1]);
	int  N  = (int)mxGetNumberOfElements(prhs[2]);
	int* xf = (int*)mxGetData(prhs[2]);
	int* yf = (int*)mxGetData(prhs[3]);

	// Shift input frequencies
	int xc = 0;
	int yc = 0;

	if (X % 2 == 0)
	{
		xc = X / 2 + 1;
	}
	else
	{
		xc = (X+1) / 2;
	}

	if (Y % 2 == 0)
	{
		yc = Y / 2 + 1;
	}
	else
	{
		yc = (Y + 1) / 2;
	}

	for (int n = 0; n < N; n++)
	{
		xf[n] -= xc;
		yf[n] -= yc;
	}

	// Create output array
	mwSize dims[] = { (mwSize)X, 
		              (mwSize)Y, 
					  (mwSize)N };

	mxArray *mArr = mxCreateNumericArray(3,
		                                 dims,
                                         mxUINT8_CLASS,
										 mxREAL);

	char* pData = (char*)mxGetData(mArr);
	
	// X increment
	#pragma loop(hint_parallel(0))
	#pragma loop(ivdep)
	for (int n = 0; n < N; n++)
	{
		char* pFrame = &pData[n*X*Y];
		char* pLine0 = pFrame;

		for (int x = 0; x < X; x++)
		{
			pLine0[x] = (char)((256 * x * xf[n]) / X);
		}

		for (int y = 1; y < Y; y++)
		{
			char* pLine = &pFrame[y*X];
			CopyMemory((void*)pLine, (void*)pLine0, X);
		}
		
	}

	// Y increment
	#pragma loop(hint_parallel(0))
	#pragma loop(ivdep)
	for (int n = 0; n < N; n++)
	{
		// Create y increment array for the current frame
		int* y_arr = new int[Y];
		for (int y = 0; y < Y; y++)
		{
			y_arr[y] = (char)((256 * y*yf[n]) / Y);
		}

		// Add to each line of the current frame
		char* pFrame = &pData[n*X*Y];
		for (int y = 0; y < Y; y++)
		{
			char* pLine = &pFrame[y*X];
			for (int x = 0; x < X; x++)
			{
				pLine[x] += y_arr[y];
			}
		}

	}
	
	// Return array
	plhs[0] = mArr;	
	return;
}