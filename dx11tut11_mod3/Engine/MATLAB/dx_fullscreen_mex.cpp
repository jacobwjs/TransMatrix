// C++/MATLAB MEX class to interface MATLAB with the fullscreen display programusing shared memory segments
// Based on class_handle.hpp by Oliver Woodford
//   - Damien Loterie (11/2013)

#include "mex.h"
#include "class_handle.hpp"
#include <windows.h>
#define _COMMUNICATIONCLASS_H_
#include "../Engine/communicationclass.h"
#define ENABLE_TRIGGERING
#include "../Engine/parameterclass.h"

// The class that we are interfacing to
class dx_comm_class
{
private:
	HANDLE 			hDataFile;
	HANDLE 			hTimeFile;
	HANDLE 			hConfigFile;
    HANDLE 			hSignal;

	unsigned char* 	pData;
	double* 	   	pTime;
	ParameterClass* pConfig;
	
public:
    dx_comm_class()
	{
        ZeroMemory(this, sizeof(dx_comm_class));
	}
	
	~dx_comm_class()
	{
		closeFiles();
	}

	bool openFiles()
	{
		// ------
		// Config
		// ------
		// Check if the config file is not already open
		if (hConfigFile || pConfig)
		{
			mexErrMsgTxt("The config file seems to be open already.\n");
            
            closeFiles();
			return false;
		}
		
		// Try to open the config file
		hConfigFile = OpenFileMapping(
									FILE_MAP_ALL_ACCESS,   		// read/write access
									FALSE,                 		// do not inherit the name
									COMM_CONFIG_FILE);    		// name of mapping object

		if (hConfigFile == NULL)
		{
			int lastError = GetLastError();
			if (lastError==2) {
				mexErrMsgTxt("Could not get handle to config file (ERROR_FILE_NOT_FOUND). Is the fullscreen window started?\n");
			} else {
				printf("Error: %d.\n", lastError);
                mexErrMsgTxt("Could not get handle to config file.\n");
			}
            
			closeFiles();
			return false;
		}

		// Try to map the memory
		pConfig = (ParameterClass*) MapViewOfFile(hConfigFile, 		  // handle to map object
												FILE_MAP_ALL_ACCESS,  // read/write permission
												0,
												0,
												sizeof(ParameterClass));

		if (pConfig == NULL)
		{
		    closeFiles();

			printf("Error: %d.\n", GetLastError());
			mexErrMsgTxt("Could not map view of config file");
			return false;
		}
		
		// -----------
		// Read config
		// -----------
		int data_size = pConfig->bufferFrameSize * pConfig->frameWidth * pConfig->frameHeight;
		int time_size = pConfig->bufferFrameSize * sizeof(*pTime);
		
		// ----
		// Data
		// ----
		// Check if the Data file is not already open
		if (hDataFile || pData)
		{
			closeFiles();
			
			mexErrMsgTxt("The Data file seems to be open already.\n");
			return false;
		}
		
		// Try to open the Data file
		hDataFile = OpenFileMapping(FILE_MAP_ALL_ACCESS,   				// read/write access
									FALSE,                 				// do not inherit the name
									COMM_DATA_FILE);     // name of mapping object

		if (hDataFile == NULL)
		{
			closeFiles();
			
			printf("Error: %d.\n", GetLastError());
			mexErrMsgTxt("Could not get handle to Data file");
			return false;
		}

		// Try to map the memory
		pData = (unsigned char*) MapViewOfFile(hDataFile, // handle to map object
												FILE_MAP_ALL_ACCESS,  // read/write permission
												0,
												0,
												data_size);

		if (pData == NULL)
		{
			closeFiles();
			
			printf("Error: %d.\n", GetLastError());
			mexErrMsgTxt("Could not map view of Data file");
			return false;
		}
		
		// ----
		// Time
		// ----
		// Check if the Data file is not already open
		if (hTimeFile || pTime)
		{
			closeFiles();
			
			mexErrMsgTxt("The Time file seems to be open already.\n");
			return false;
		}
		
		// Try to open the Time file
		hTimeFile = OpenFileMapping(FILE_MAP_ALL_ACCESS,   				// read/write access
									FALSE,                 				// do not inherit the name
									COMM_TIME_FILE);     // name of mapping object

		if (hTimeFile == NULL)
		{
			closeFiles();
			
			printf("Error: %d.\n", GetLastError());
			mexErrMsgTxt("Could not get handle to Time file");
			return false;
		}

		// Try to map the memory
		pTime = (double*) MapViewOfFile(hTimeFile, // handle to map object
										FILE_MAP_ALL_ACCESS,  // read/write permission
										0,
										0,
										time_size);

		if (pTime == NULL)
		{
			closeFiles();
			
			printf("Error: %d.\n", GetLastError());
			mexErrMsgTxt("Could not map view of Time file");
			return false;
		}
		
        
		// ------
		// Signal
		// ------ 
        hSignal = OpenEvent(SYNCHRONIZE | EVENT_MODIFY_STATE ,
                            false,
                            COMM_SIGNAL);
        if (hSignal == NULL)
        {
            char errorMsg[256];
            sprintf_s(errorMsg, sizeof(errorMsg), "Could not open the signal object (OpenEvent() Error %d).",GetLastError());
            MessageBox(NULL, errorMsg, "Error", MB_OK);

            closeFiles();
            return false;
        }
        
        
		return true;
	}
	
	void closeFiles()
	{
        if(pData)
        {
            UnmapViewOfFile(pData);
            pData = 0;
        }

        if (hDataFile) {
            CloseHandle(hDataFile);
            hDataFile = 0;
        }

        if(pTime) 
        {
            UnmapViewOfFile(pTime);
            pTime = 0;
        }

        if (hTimeFile)
        {
            CloseHandle(hTimeFile);
            hTimeFile = 0;
        }

        if(pConfig) 
        {
            UnmapViewOfFile(pConfig);
            pConfig = 0;
        }

        if (hConfigFile) 
        {
            CloseHandle(hConfigFile);
            hConfigFile = 0;
        }

        if (hSignal) 
        {
            CloseHandle(hSignal);
            hSignal = 0;
        }
		return;
	}
	
	mxArray* recastArray(const mxArray* mArr, mxClassID mType)
	{
		// Get string to pass to 'cast'
		mxArray* mxCastString;
		switch (mType)
		{
			case mxINT8_CLASS:
				mxCastString = mxCreateString("int8");
				break;
			case mxUINT8_CLASS:
				mxCastString = mxCreateString("uint8");
				break;
			case mxINT16_CLASS:
				mxCastString = mxCreateString("int16");
				break;
			case mxUINT16_CLASS:
				mxCastString = mxCreateString("uint16");
				break;	
			case mxINT32_CLASS:
				mxCastString = mxCreateString("int32");
				break;
			case mxUINT32_CLASS:
				mxCastString = mxCreateString("uint32");
				break;	
			case mxINT64_CLASS:
				mxCastString = mxCreateString("int64");
				break;
			case mxUINT64_CLASS:
				mxCastString = mxCreateString("uint64");
				break;					
			case mxSINGLE_CLASS:
				mxCastString = mxCreateString("single");
				break;	
			case mxDOUBLE_CLASS:
				mxCastString = mxCreateString("double");
				break;	
			case mxLOGICAL_CLASS:
				mxCastString = mxCreateString("logical");
				break;					
			default:
				mexErrMsgTxt("Unknown type.");
				return 0;
				break;
		}
		
		// Call 'cast'
		int result;
		mxArray* plhs[1];
		mxArray* prhs[] = {(mxArray*)mArr, mxCastString};
		
		result = mexCallMATLAB(1, plhs, 2, prhs, "cast");
		
		if (result!=0)
		{
			mexErrMsgTxt("Cast failed.");
			return 0;
		}
		
		// Return
		return plhs[0];
	}
	
	
	mxArray* getSetProperty(char* field, const mxArray* mArray, bool set)
	{
		// Initialize defaults
		void* 	 mData;
		
		// Macro to simplify case definition
		#define FIELD(name, readOnly, cType, sType, numel) 									\
		if (strcmp(field,#name)==0)                    										\
		{                                              										\
				if (set)																	\
				{																			\
					if (readOnly) 															\
					{           														    \
						mexErrMsgTxt("The property "#name" is read-only.");      			\
						return 0;          													\
					}           															\
					else           															\
					{           															\
						if (mxGetNumberOfElements(mArray)!=numel) {							\
							mexErrMsgTxt("Property "#name" must have "#numel" elements."); 	\
							return 0;														\
						}																	\
																							\
						mxClassID mType = mxGetClassID(mArray);								\
																							\
						if (mType != sType) {												\
							mxArray* mRecast = recastArray(mArray, sType);					\
							mData = mxGetData(mRecast);										\
						} else {															\
							mData = mxGetData(mArray);										\
						}																	\
																							\
						CopyMemory(&(pConfig->name), mData, sizeof(pConfig->name));         \
																							\
						return 0;															\
					}           															\
				}																			\
				else																		\
				{																			\
					mxArray* mOut = mxCreateNumericMatrix(numel, 1, sType, mxREAL);			\
																							\
					mData = mxGetData(mOut);												\
					CopyMemory(mData, &(pConfig->name), sizeof(pConfig->name));             \
																							\
					return mOut;															\
				}																			\
		}																					\
		else  
		
		// Cases for different fields	
		#include "../Engine/parameters.def"
		{	
			char errorMsg[4096] = {'\0'};
			if (sprintf_s(errorMsg, sizeof(errorMsg), "The property name '%s' is invalid.", field)>0)
			{
				mexErrMsgTxt(errorMsg);
			}
			else
			{
				mexErrMsgTxt("The property name is invalid.");
			}
		}

		return 0;
	}
	
	mxArray* getAllProperties()
	{
		// Count number of fields
		int nfields = 0;
		#define FIELD(name, readOnly, cType, sType, numel)  nfields++;
		#include "../Engine/parameters.def"
		
		// Get field name for each field
		char** fieldnames = new char*[nfields];
		nfields = 0;
		#define FIELD(name, readOnly, cType, sType, numel)  fieldnames[nfields++] = #name;
		#include "../Engine/parameters.def"
	
		// Declare structure
		mxArray* mOut = mxCreateStructMatrix(1, 1, nfields, (const char **)fieldnames);
		
		// Get all relevant values
		for (int i=0; i<nfields; i++) {
			mxSetField(mOut, 0, fieldnames[i], getSetProperty(fieldnames[i], nullptr, false));
		}
		
		// Return
		return mOut;
	}
	

	void putData(int startIndex, const mxArray* input) {
		// Check type
		if (!mxIsUint8(input) || mxIsComplex(input)) 
		{
			mexErrMsgTxt("The data type must be 'uint8' (real, not complex).");
		}
		
		// Check dimensions
        const mwSize *dims = mxGetDimensions(input);
        int   copySize;
		if (mxGetNumberOfDimensions(input)==2) 
		{
			copySize = dims[0]*dims[1];
		}
        else if (mxGetNumberOfDimensions(input)==3) 
        {
            copySize = dims[0]*dims[1]*dims[2];
            if ( (startIndex+dims[2]) > pConfig->bufferFrameSize )
            {
                mexErrMsgTxt("The data contains too many frames for the buffer.");
            }
        }
        else
        {
            mexErrMsgTxt("The data must have 2 dimensions (width x height) or 3 dimensions (width x height x frames).");
        }

		// Check sizes
		if (   dims[0] != pConfig->frameWidth
		    || dims[1] != pConfig->frameHeight) 
		{
			mexErrMsgTxt("The size of the frames in the input data does not match the size of the frames in the buffer.");
		}

		// Copy
		unsigned char* pSource = (unsigned char*)mxGetData(input);
		unsigned char* pDest   = pData + startIndex * (pConfig->frameWidth * pConfig->frameHeight);
		CopyMemory(pDest, pSource,  copySize);
	}
	
	mxArray* getTime(int startIndex, int numberOfFrames) {
		// Check sizes
		if ( (startIndex+numberOfFrames) > pConfig->bufferFrameSize) 
		{
			mexErrMsgTxt("The requested data is too big compared to the buffer.");
		}
		
		// Create array
		mxArray* result;
		result = mxCreateNumericMatrix(1, numberOfFrames, mxDOUBLE_CLASS, mxREAL);
		
		// Copy
        CopyMemory(
                   mxGetData(result),               // Destination
                   &pTime[startIndex],              // Source
                   numberOfFrames * sizeof(*pTime)  // Size
                  );
		
		// Return
		return result;
	}
	
    bool waitForSignal(int timeoutMilliseconds)
    {
        // Wait for the signal
        int result = WaitForSingleObject(hSignal, timeoutMilliseconds);
        
        // Check the reason for the end of the wait
        if (result == WAIT_OBJECT_0)
        {
            return true;
        }
        else if (result == WAIT_TIMEOUT)
        {
            mexErrMsgTxt("waitForSignal timed out.");
            return false;
        } else {
            // Note: you can check the error by looking at the result
            //       (WaitForSingleObject error code) and GetLastError()
            mexErrMsgTxt("waitForSignal failed.");
            return false;
        }
    }
    
    bool resetSignal()
    {
        // Reset the signal
        int result = ResetEvent(hSignal);
        
        // Check the result
        if (result==0)
        {
            mexErrMsgTxt("resetSignal failed.");
            return false;
        } else {
            return true;
        }
    }

};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
    // Get the command string
    char cmd[64];
	if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd)))
		mexErrMsgTxt("First input should be a command string less than 64 characters long.");
        
    // New
    if (strcmp("new", cmd)==0) {
        // Check parameters
        if (nlhs != 1)
            mexErrMsgTxt("New: One output expected.");
        // Return a handle to a new C++ instance
        plhs[0] = convertPtr2Mat<dx_comm_class>(new dx_comm_class);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
	{
		mexErrMsgTxt("Second input should be a class instance handle.");
    }
	
    // Delete
    if (strcmp("delete", cmd)==0) {
        // Destroy the C++ object
        destroyObject<dx_comm_class>(prhs[1]);
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    }
    
    // Get the class instance pointer from the second input
    dx_comm_class *dx_comm_instance = convertMat2Ptr<dx_comm_class>(prhs[1]);
    
    // Call the various class methods
    // openFiles  
    if (strcmp("openFiles", cmd)==0) {
        // Check parameters
        if (nlhs > 1 || nrhs != 2)
            mexErrMsgTxt("openFiles: Unexpected arguments.");
			
		// Prepare output variables
		plhs[0] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS ,mxREAL);
		int* result = (int*)mxGetData(plhs[0]);
		
        // Call the method
        *result = dx_comm_instance->openFiles();
        return;
    }
	
    // closeFiles   
    if (strcmp("closeFiles", cmd)==0) {
        // Check parameters
        if (nlhs != 0 || nrhs != 2)
            mexErrMsgTxt("closeFiles: Unexpected arguments.");
			
        // Call the method
        dx_comm_instance->closeFiles();
        return;
    }
	
    // getConfig  
    if (strcmp("getConfig", cmd)==0) {
        // Check parameters
        if (nlhs != 1 || (nrhs != 2 && nrhs != 3))
            mexErrMsgTxt("getConfig: Unexpected arguments.");
		char field[64];
		if (nrhs==3 && mxGetString(prhs[2], field, sizeof(field)))
			mexErrMsgTxt("getConfig: Input should be a field name less than 64 characters long.");
        
        // Call the method
		if (nrhs==3)
		{
			plhs[0] = dx_comm_instance->getSetProperty(field, nullptr, false);
		}
		else
		{
			plhs[0] = dx_comm_instance->getAllProperties();
		}
        return;
    }
	
    // setConfig  
    if (strcmp("setConfig", cmd)==0) {
        // Check parameters
        if (nlhs != 0 || nrhs != 4)
            mexErrMsgTxt("setConfig: Unexpected arguments.");
			
		// Get first parameter
		char field[64];
		if (mxGetString(prhs[2], field, sizeof(field)))
			mexErrMsgTxt("setConfig: Parameter #1 should be a field name less than 64 characters long.");
			
		// // Get second parameter
		// if (!mxIsInt32(prhs[3]))
			// mexErrMsgTxt("setConfig: Parameter #2 should be an integer.");
		// int  input = *((int*)mxGetData(prhs[3]));
			
        // Call the method
        // dx_comm_instance->setConfig(field, input);
		dx_comm_instance->getSetProperty(field, prhs[3], true);
		
        return;
    }
	
    // putData
    if (strcmp("putData", cmd)==0) {
        // Check parameters
        if (nlhs != 0 || nrhs != 4)
            mexErrMsgTxt("putData: Unexpected arguments.");
			
		// Get first parameter
		if (!mxIsInt32(prhs[2]))
			mexErrMsgTxt("putData: Parameter #1 should be an integer.");
		int startIndex = *((int*)mxGetData(prhs[2]));
			
		// The second parameter is validated in the putData method
		
        // Call the method
        dx_comm_instance->putData(startIndex, prhs[3]);
        return;
    }
	
    // getTime
    if (strcmp("getTime", cmd)==0) {
        // Check parameters
        if (nlhs != 1 || nrhs != 4)
            mexErrMsgTxt("getTime: Unexpected arguments.");
			
		// Check both parameters
		if (!mxIsInt32(prhs[2]) || !mxIsInt32(prhs[3]))
			mexErrMsgTxt("getTime: parameters should be integers.");
	
		// Get the parameters
		int  startIndex     = *((int*)mxGetData(prhs[2]));
		int  numberOfFrames = *((int*)mxGetData(prhs[3]));

        // Call the method
        plhs[0] = dx_comm_instance->getTime(startIndex, numberOfFrames);
        return;
    }
	
    // waitForSignal  
    if (strcmp("waitForSignal", cmd)==0) {
        // Check parameters
        if (nlhs != 0 || nrhs != 3)
            mexErrMsgTxt("waitForSignal: Unexpected arguments.");
			
		// Get first parameter
		if (!mxIsInt32(prhs[2]))
			mexErrMsgTxt("waitForSignal: Parameter should be an integer.");
		int  input = *((int*)mxGetData(prhs[2]));
			
        // Call the method
        dx_comm_instance->waitForSignal(input);
        return;
    }
    
    // resetSignal  
    if (strcmp("resetSignal", cmd)==0) {
        // Check parameters
        if (nlhs != 0 || nrhs != 2)
            mexErrMsgTxt("resetSignal: Unexpected arguments.");
			
        // Call the method
        dx_comm_instance->resetSignal();
        return;
    }    
	
    // Got here, so command not recognized
    mexErrMsgTxt("Command not recognized.");
}
