// C++/MATLAB MEX interface with the fullscreen display program
// - Damien Loterie (05/2014)

#include "mex.h"
#include <windows.h>
#define _COMMUNICATIONCLASS_H_
#include "../Engine/communicationclass.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
        // Check parameters
        if (nrhs != 0)
            mexErrMsgTxt("Unexpected arguments.");

		// Open Mutex
		HANDLE hMutex = OpenMutex(SYNCHRONIZE, FALSE, COMM_MUTEX);
		
		// Determine if it is open
		bool state = (hMutex != NULL);
		
		// Release
		ReleaseMutex(hMutex);
		CloseHandle(hMutex);
		
		// Prepare output variables
		plhs[0] = mxCreateNumericMatrix(1, 1, mxLOGICAL_CLASS ,mxREAL);
		bool* result = (bool*)mxGetData(plhs[0]);
		*result = state;
		
		// Return
		return;
}