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

		// Open shared signal
		HANDLE hSignal = OpenEvent(SYNCHRONIZE, FALSE, COMM_SIGNAL);
		
		// If the signal does not exist, leave with exit code -1
		if (hSignal == NULL)
		{
			plhs[0] = mxCreateString("signal does not exist");
			return;
		}
		
		// If it exists, wait for the signalled state
        int waitResult = WaitForSingleObject(hSignal, 10000);
        
        // Check the reason for the end of the wait
        if (waitResult == WAIT_OBJECT_0)
        {
            plhs[0] = mxCreateString("signalled");
        }
        else if (waitResult == WAIT_TIMEOUT)
        {
            plhs[0] = mxCreateString("timeout");
        }
		else
		{
            plhs[0] = mxCreateString("WaitForSingleObject error");
        }
		
		// Reset the signal
        ResetEvent(hSignal);
		
		// Release
		CloseHandle(hSignal);
		
		// Return
		return;
}