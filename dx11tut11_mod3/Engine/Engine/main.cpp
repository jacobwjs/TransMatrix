////////////////////////////////////////////////////////////////////////////////
// Filename: main.cpp
// Startup code for the DirectX interface application
//   - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#include "systemclass.h"
#include "parameterclass.h"
#include "errors.h"

// Forward declaration
bool parseArguments(char*, int*);



// Main
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCommand, int iCmdshow)
{
	SystemClass* System = 0;
	ParameterClass* params = 0;
	HANDLE hMutex = 0;
	bool result;
	int  exitCode = -1;

	// Check that only one instance is running
	bool AlreadyRunning;
	hMutex = CreateMutex(NULL, TRUE, COMM_MUTEX);
	AlreadyRunning = (GetLastError() == ERROR_ALREADY_EXISTS);
	if (AlreadyRunning)
	{
		exitCode = 1;
		goto Close;
	}

	// Redirect error messages
	FILE* pErrorFile;
	int result2 = freopen_s(&pErrorFile, ERROR_FILE, "w", stderr);
	if (result2 != 0)
	{
		MessageBox(NULL, "Could not redirect error stream.", "Error", MB_OK);
		goto Close;
	}

	// Read input parameters
	params = new ParameterClass;

	/// FIXME:
	/// - This should be more elegant and flexible in the future. For now removing.
	if (pCommand[0] == 0)
	{
		result = params->Parse(PARAMETER_DEFAULT_FILE);
	}
	else
	{
		result = params->Parse(pCommand);
	}
	
	if(!result)
	{
		ReportError("Failed to load the startup configuration.");
		goto Close;
	}

	// Create the system object.
	System = new SystemClass;
	if(!System)
		goto Close;


	// Initialize the system object.
	result = System->Initialize(params);
	if (!result)
		goto Close;

	// Run
	result = System->Run();
	if (result)
		exitCode = 0;

	
Close:
	// Shutdown and release the system object.
	if (System)
	{
		System->Shutdown();
		delete System;
		System = 0;
	}

	// Release parameters
	if (params)
		delete params;

	// Release the mutex
	if (hMutex)
	{
		ReleaseMutex(hMutex);
		CloseHandle(hMutex);
	}

	// MessageBox in case of error
	if (exitCode<0) {
		MessageBox(NULL, "Application ended on an error. Please check " ERROR_FILE ".", "Error", MB_OK);
	}

	return exitCode;
}


