// Object allowing interprocess communication with e.g. MATLAB.
//  - Damien Loterie (01/2014)

#include "communicationclass.h"
#include "errors.h"

CommunicationClass::CommunicationClass()
{
	ZeroMemory(this,sizeof(CommunicationClass));
}


CommunicationClass::CommunicationClass(const CommunicationClass& other)
{
}


CommunicationClass::~CommunicationClass()
{
}



bool CommunicationClass::Initialize(ParameterClass* params)
{
	BOOL result;

	// Get inputs
	numberOfFrames = params->bufferFrameSize;
	bytesPerFrame = (params->frameWidth) * (params->frameHeight);

	// Determine the sizes
	int data_size = numberOfFrames * bytesPerFrame;
	int time_size = numberOfFrames * sizeof(*pTime);
	
	// ---------
	// Data file
	// ---------
	hDataFile = CreateFileMapping(
                 INVALID_HANDLE_VALUE,				// use paging file
                 NULL,								// default security
                 PAGE_READWRITE,					// read/write access
                 0,									// maximum object size (high-order DWORD)
                 data_size,							// maximum object size (low-order DWORD)
                 COMM_DATA_FILE);					// name of mapping object

   if (hDataFile == NULL)
   {
	  ReportError("Could not create file mapping object for the Data file (CreateFileMapping() Error %d).",GetLastError());

	  Shutdown();
      return false;
   }

   pData = (byte*) MapViewOfFile(hDataFile,			 // handle to map object
								FILE_MAP_ALL_ACCESS, // read/write permission
								0,
								0,
								data_size);

   if (pData == NULL)
   {
		ReportError("Could not map view for the Data file (MapViewOfFile() Error %d).",GetLastError());

		Shutdown();
		return false;
   }

	// ---------
	// Time file
   	// ---------
	hTimeFile = CreateFileMapping(
                 INVALID_HANDLE_VALUE,				// use paging file
                 NULL,								// default security
                 PAGE_READWRITE,					// read/write access
                 0,									// maximum object size (high-order DWORD)
                 time_size,							// maximum object size (low-order DWORD)
                 COMM_TIME_FILE);	// name of mapping object

   if (hTimeFile == NULL)
   {
	    ReportError("Could not create file mapping object for the Time file (CreateFileMapping() Error %d).",GetLastError());

		Shutdown();
		return false;
   }

   pTime = (double*) MapViewOfFile(hTimeFile,			 // handle to map object
								FILE_MAP_ALL_ACCESS,	 // read/write permission
								0,
								0,
								time_size);

   if (pTime == NULL)
   {
	    ReportError("Could not map view for the Time file (MapViewOfFile() Error %d).",GetLastError());

		Shutdown();
		return false;
   }

	// -----------
   	// Config file
   	// -----------
	hConfigFile = CreateFileMapping(
                 INVALID_HANDLE_VALUE,				// use paging file
                 NULL,								// default security
                 PAGE_READWRITE,					// read/write access
                 0,									// maximum object size (high-order DWORD)
                 sizeof(ParameterClass),			// maximum object size (low-order DWORD)
                 COMM_CONFIG_FILE);					// name of mapping object

   if (hConfigFile == NULL)
   {
	    ReportError("Could not create file mapping object for the Config file (CreateFileMapping() Error %d).",GetLastError());

		Shutdown();
		return false;
   }

   pConfig = (ParameterClass*) MapViewOfFile(hConfigFile,			 // handle to map object
											FILE_MAP_ALL_ACCESS,	 // read/write permission
											0,
											0,
											sizeof(ParameterClass));

   if (pConfig == NULL)
   {
	    ReportError("Could not map view for the Config file (MapViewOfFile() Error %d).",GetLastError());

		Shutdown();
		return false;
   }

   	// ----------------------------
   	// Initialize pointers and data
   	// ----------------------------
	ZeroMemory(pData,data_size);
	ZeroMemory(pTime,time_size);
	CopyMemory(pConfig,params,sizeof(ParameterClass));

	// ------------
	// Event handle
	// ------------
	hSignal = CreateEvent(NULL,
						  true,
						  false,
						  COMM_SIGNAL);
	if (hSignal == NULL)
	{
		ReportError("Could not create the signal object (CreateEvent() Error %d).", GetLastError());

		Shutdown();
		return false;
	}

	// ------------------
   	// Performace counter
   	// ------------------
	result =  QueryPerformanceCounter(&presentTimeReference);
	result &= QueryPerformanceFrequency(&presentTimeFrequency);
	if (!result) {
		ReportError("Could not get timing information (QueryPerformanceCounter() or QueryPerformanceFrequency() Error %d).",GetLastError());

		Shutdown();
		return false;
	}


	// ----------------
   	// Triggering class
   	// ----------------
	#ifdef ENABLE_TRIGGERING
		// Create the pulse object.
		pPulse = new PulseClass();
		if(!pPulse)
		{
			Shutdown();
			return false;
		}

		// Initialize the pulse object.
		result = pPulse->Initialize(pConfig);
		if(!result)
		{
			Shutdown();
			return false;
		}
	#endif

	return true;
}


void CommunicationClass::Shutdown()
{
	// Release the shared memory resources
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

	// Release pulse object
	#ifdef ENABLE_TRIGGERING
		if (pPulse)
		{
			pPulse->Shutdown();
			pPulse = 0;
		}
	#endif
	

	return;
}

bool CommunicationClass::PreProcess(ID3D11DeviceContext* deviceContext, TextureClass* texture)
{
	bool result;

	// Check if run state was changed
	if (pConfig->run != previousRunState) {
		// Case of a transition from false to true
		if (pConfig->run == true) {
			// Reset the dividerCounter so that the current frame is presented immediately
			dividerCounter = 0;

			// If at the start of a sequence (frameCounter==0), keep the time of the first frame
			if (pConfig->frameCounter==0)
				keepRunTime = true;
		}
		previousRunState = pConfig->run;
	}

	// If running
	if (pConfig->run) {
		// Count cycles and load next frame if needed
		if (dividerCounter <= 0 || pConfig->frameRateDivider <= 0)
		{
			// Check if the previous frame was the last frame while in movie mode
			if (pConfig->frameCounter>=pConfig->stopAfterFrame && pConfig->frameRateDivider>0)
			{
				// Flag that this was the last frame cycle, so that the run flag will 
				// be cleared in the PostProcess function, and a signal will be sent.
				// (However, we do not actually load the next frame.)
				lastFrame = true;
			}
			else 
			{
				// Load next frame
				result = LoadFrame(deviceContext, texture);
				if (!result)
					return false;
			}
			dividerCounter = pConfig->frameRateDivider - 1;
		}
		else
		{
			dividerCounter--;
		}

	}

	return true;

}

bool CommunicationClass::LoadFrame(ID3D11DeviceContext* deviceContext, TextureClass* texture) {
	bool result;
	byte* next_frame_pointer;

	// Check if the pointers are not zero
	if (deviceContext && texture && pData && pConfig)
	{
		// Calculate pointer
		next_frame_pointer = pData + pConfig->bufferFrameIndex*bytesPerFrame;

		// Update texture
		result = texture->Update(deviceContext, next_frame_pointer);
		if (!result)
			return false;

		// Flag update
		frameUpdated = true;
	}
	else
	{
		return false;
	}

	return true;
}

bool CommunicationClass::PostProcess(D3DClass* d3dclass) 
{
	// Keep reference time
	if (keepRunTime) {
		GetSystemTime(&(pConfig->startTime));
		presentTimeReference = d3dclass->GetPresentTime();
		keepRunTime = false;
	}

	// Send pulse if needed
	#ifdef ENABLE_TRIGGERING
		if (!pPulse->Process(frameUpdated))
			return false;
	#endif


	if (frameUpdated)
	{
		// Save time of blank
		SaveTime(d3dclass);

		// Count frame
		pConfig->frameCounter++;

		// Move the buffer position to the following frame
		pConfig->bufferFrameIndex = GetZeroBasedIndexForNextFrame();

		// In single frame mode (frameRateDivider==0), stop immediately after the first frame.
		if (pConfig->frameRateDivider <= 0) {
			lastFrame = true;
		}

		// Frame update was handled
		frameUpdated = false;
	}

	// Trigger signal if we reached the last frame, or the signal point.
	if (lastFrame 
		|| (pConfig->signalOnFrame>0 && pConfig->frameCounter == pConfig->signalOnFrame)
		|| pConfig->signalNow)
	{
		if (!SetEvent(hSignal))
		{
			ReportError("SetEvent failed.");
			return false;
		}
		else
		{
			pConfig->signalNow = false;
		}
	}

	// Additionally, if we reached the last frame, clear the run flag.
	if (lastFrame)
	{
		// Stop running
		pConfig->run = false;

		//// Freeze on this last frame
		//pConfig->frameRateDivider = 0;

		// Last frame event was handled
		lastFrame = false;
	}

	return true;
}

bool CommunicationClass::SaveTime(D3DClass* d3dclass)  {
	// Calculate pointer
	int size = sizeof(double);

	if (!pConfig->processingTimes) {
		// Calculate time
		pTime[pConfig->bufferFrameIndex] = ((double)(d3dclass->GetPresentTime().QuadPart-presentTimeReference.QuadPart))/((double)presentTimeFrequency.QuadPart);
	} else {
		// Calculate processing time instead
		pTime[pConfig->bufferFrameIndex] = ((double)d3dclass->GetProcessingTime().QuadPart)/((double)presentTimeFrequency.QuadPart);
	}
	
	return true;
}

int CommunicationClass::GetZeroBasedIndexForNextFrame()
{
	if (pConfig->bufferFrameIndex < (numberOfFrames-1)) {
		return pConfig->bufferFrameIndex + 1;
	} else {
		return 0;
	}
}

ParameterClass* CommunicationClass::GetSharedParameters() {
	return pConfig;
}