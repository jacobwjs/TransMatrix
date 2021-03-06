// Class that will connect to the camera, listen for incoming frames, and store
// them in memory. This happens in a dedicated high-priority thread, to avoid
// frame drops. There is a basic error reporting mechanism.
//  - Damien Loterie (11/2014)
//
// Update 12/2015 (Jacob Staley)
//  - The gigesource class has been updated to work with the latest version of 
//    the eBUS SDK, which abstracts the connection process and allows interfacing
//    with various connection protocols (GigE Vision, USB3 Vision, and GenICam).


#include <tchar.h>
#include "gigesource.h"


GigE_Source::GigE_Source()
{
	ManagerThread = NULL;
	ManagerSignal = NULL;

	/// ------------------------------ JWJS -------------------------
	lPvSystem = new PvSystem;
	/// -------------------------------------

}


GigE_Source::~GigE_Source()
{
	/// -------------------------------------- JWJS --------------------
	if (lDevice != NULL)
	{
		delete lDevice;
		lDevice = NULL;
	}

	if (lPvSystem != NULL)
	{
		delete lPvSystem;
		lPvSystem = NULL;
	}
	/// ---------------------------------------------
}

PvResult GigE_Source::Initialize(const PvString camera_identifier)
{
	/// Initialize results variable
	PvResult result;
	
	/// ------------------ JWJS -------------------------------------------------

	/// Ensure a device has been selected.
	/// NOTE:
	///  - 'lDeviceInfo' should never be NULL if called from Matlab (via mex). If we make it
	///    here from Matlab and 'lDeviceInfo' is NULL the device discovery failed.
	/// ------------------------------------------------------------------------------------ 
	if ((lDeviceInfo == NULL) && 
		(camera_identifier.GetLength() == 0))
	{
		/// If the user didn't provide a 'camera_identifier' and had not previously 
		/// selected a device, then provide a list of all potential devices via the 
		/// commandline and get the users choice.
		lDeviceInfo = SelectDevice(lPvSystem);
	}
	else if ((lDeviceInfo == NULL) &&
		(camera_identifier.GetLength() != 0))
	{
		/// No selection has been previously made, but the user provided which device
		/// to select.
		PvCheck(lPvSystem->FindDevice(camera_identifier, &lDeviceInfo), Shutdown(););
	}


	/// We assume a suitable device has been selected if we make it here.
	if (lDeviceInfo != NULL)
	{

		/// Connect to the vision device (GigE or USB3).
		/// --------------------------------------------------------------------------------
		lDevice = ConnectToDevice(lDeviceInfo);
		if (lDevice == NULL)
		{
			PvDevice::Free(lDevice);
			return PvResult(PvResult::Code::NOT_CONNECTED, PvString("ERROR. ConnectToDevice() failure."));
		}

		/// Open stream from vision device (GigE or USB3).
		/// --------------------------------------------------------------------------------
		lStream = OpenStream(lDeviceInfo);
		if (lStream == NULL)
		{
			lDevice->Disconnect();
			PvDevice::Free(lDevice);
			PvStream::Free(lStream);
			return PvResult(PvResult::Code::GENERIC_ERROR, PvString("ERROR. OpenStream() failure."));
		}


		/// Configure the stream that was opened.
		/// --------------------------------------------------------------------------------
		ConfigureStream();

		/// Manage buffers.
		/// --------------------------------------------------------------------------------
		lDeviceParams = lDevice->GetParameters();
		
		
	}
	/// ----------------------------------

	
	////////////////////
	// BUFFER MANAGER //
	////////////////////
	// Configure buffer size
	PvCheck(lDeviceParams->GetIntegerValue("PayloadSize", bufferSize));

	// Create signal
	ManagerSignal = CreateEvent(NULL, false, false, NULL);
	if (ManagerSignal == NULL)
		return PvResult(PvResult::Code::GENERIC_ERROR, PvString("Could not create the synchronization signal."));

	// Start thread
	ManagerThread = CreateThread(NULL, 0, ManagerStaticStart, (void*)this, 0, NULL);
	if (ManagerThread == NULL)
		return PvResult(PvResult::Code::THREAD_ERROR, PvString("Could not start the buffer manager thread."));

	// Wait for signal
	DWORD WaitResult = WaitForSingleObject(ManagerSignal, 10000);
	if (WaitResult != WAIT_OBJECT_0)
		return PvResult(PvResult::Code::THREAD_ERROR, PvString("Buffer manager signal timed out."));

	////////////
	// RETURN //
	////////////
	return PvResult(PvResult::Code::OK);
}


void GigE_Source::Shutdown()
{
	// Stop buffer manager
	if (ManagerThread != NULL)
	{
		ManagerStopFlag = true;
		DWORD WaitResult = WaitForSingleObject(ManagerThread, 10000);
		if (WaitResult != WAIT_OBJECT_0)
			MessageBox(NULL, _T("Manager thread does not respond."), _T("Error"), MB_OK | MB_ICONERROR);
		CloseHandle(ManagerThread);
	}

	// Close manager signal
	CloseHandle(ManagerSignal);

	// Abort buffers
	if (lStream != NULL)
	{
		lStream->AbortQueuedBuffers();
	}


	// Empty lStream buffer queue
	PvBuffer* pBuffer;
	PvResult resBuffer;

	if (lStream != NULL)
	{
		while (lStream->RetrieveBuffer(&pBuffer, &resBuffer, 0).IsOK())
		{
			pBuffer->Free();
			delete pBuffer;
		}
	}

	// Empty SPSC_queue
	std::unique_ptr<PvBuffer> upBuffer;
	while (upBuffer = queue.TryPop())
		upBuffer.reset();

	// Close stream
	if (lStream != NULL)
	{
		lStream->Close();
	}


	// Disconnect device
	if (lDevice != NULL)
	{
		lDevice->Disconnect();
	}
	
}


PvResult GigE_Source::Start()
{
	PvResult result;

	// Check if thread is still running
	DWORD threadExitCode;
	GetExitCodeThread(ManagerThread, &threadExitCode);
	if (threadExitCode != STILL_ACTIVE)
		return PvResult(PvResult::Code::THREAD_ERROR, "Buffer manager thread has stopped.");

	// Verify buffer sizes
	int64_t lSize = 0;
	PvCheck(lDeviceParams->GetIntegerValue("PayloadSize", lSize));
	if (lSize != bufferSize)
	{
		// Update buffer size
		bufferSize = lSize;

		// Abort previous buffer queue
		lStream->AbortQueuedBuffers();

		// Regenerate the buffer queue
		ManagerFlushFlag = true;

		// Wait for completion
		DWORD WaitResult = WaitForSingleObject(ManagerSignal, 10000);
		if (WaitResult != WAIT_OBJECT_0)
			return PvResult(PvResult::Code::THREAD_ERROR, PvString("Buffer manager signal timed out."));

	}
	
	// Reset timestamps;
	PvCheck(lDeviceParams->ExecuteCommand("GevTimestampControlReset"));

	// Lock parameters
	PvCheck(lDeviceParams->SetIntegerValue("TLParamsLocked", 1));

	// Enable streaming and send the AcquisitionStart command
	cout << "Enabling streaming and sending AcquisitionStart command." << endl;
	lDevice->StreamEnable();
	PvCheck(lDeviceParams->ExecuteCommand("AcquisitionStart"), lDeviceParams->SetIntegerValue("TLParamsLocked", 0););

	// Return success
	return PvResult(PvResult::Code::OK);
}

PvResult GigE_Source::Stop()
{
	// Stop acquisition
	PvResult resStop = lDeviceParams->ExecuteCommand("AcquisitionStop");

	// Unlock parameters
	PvResult result;
	PvCheck(lDeviceParams->SetIntegerValue("TLParamsLocked", 0));

	// Return error code
	return resStop;
}

DWORD WINAPI GigE_Source::ManagerStaticStart(LPVOID lpParams)
{
	GigE_Source* gigesource = (GigE_Source*)lpParams;
	return gigesource->ManageBuffers();
}

#include <sstream>
#include <iostream>
#include <fstream>
DWORD GigE_Source::ManageBuffers()
{
	PvBuffer* pBuffer;
	PvResult resQueue, resRetrieve, resBuffer;

	//// Debug log file
	//QueryPerformanceCounter(&ManagerT2);
	//std::ofstream myfile("gige_manager_log.txt");

	// Thread priority
	SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST); //THREAD_PRIORITY_TIME_CRITICAL

	// Continuous loop for buffer retrieve/create
	ManagerStopFlag = false;
	ManagerFlushFlag = true;
	while (!ManagerStopFlag)
	{
		// Flush option
		if (ManagerFlushFlag)
		{
			// Empty buffer queue
			while (lStream->RetrieveBuffer(&pBuffer, &resBuffer, 0).IsOK())
			{
				pBuffer->Free();
				delete pBuffer;
			}

			// Fill buffer queue
			for (uint32_t i = lStream->GetQueuedBufferCount(); i < lStream->GetQueuedBufferMaximum(); i++)
			{
				pBuffer = new PvBuffer();
				pBuffer->Alloc((uint32_t)bufferSize);
				resQueue = lStream->QueueBuffer(pBuffer);
				if (!resQueue.IsSuccess())
					return EXIT_FAILURE;
			}

			// Signal the flush is done
			SetEvent(ManagerSignal);

			// Do this only once
			ManagerFlushFlag = false;
		}

		//// Timing
		//QueryPerformanceCounter(&ManagerT1);

		// Retrieve buffer
		resRetrieve = lStream->RetrieveBuffer(&pBuffer, &resBuffer, 1000);

		//// Timing
		//LARGE_INTEGER freq;
		//QueryPerformanceFrequency(&freq);
		//double delta_t = ((double)(ManagerT1.QuadPart - ManagerT2.QuadPart)) / ((double)freq.QuadPart);
		//myfile << delta_t;
		//if (resRetrieve.IsOK())
		//	myfile << " (OK)";
		//myfile << "\n";
		//QueryPerformanceCounter(&ManagerT2);

		// Check if retrieve is successful
		if (resRetrieve.IsOK())
		{
			// Create a new unique pointer for the acquired buffer
			auto upBuffer = std::unique_ptr<PvBuffer>(pBuffer);

			// Check if acquisition is succesful and if it's an image
			if (resBuffer.IsOK() && pBuffer->GetPayloadType()==PvPayloadType::PvPayloadTypeImage)
			{
				// Push buffer in the queue
				queue.TryPush(upBuffer);

				// Turn "OK" into an error if this push operation failed
				if (upBuffer)
					resBuffer = PvResult(PvResult::Code::GENERIC_ERROR, PvString("Buffer queuing operation failed."));
			}

			// Register an error if needed, except for a manual abort
			if (!resBuffer.IsOK() && resBuffer.GetCode()!=PvResult::Code::ABORTED)
				ManagerErrors.TryPush(std::unique_ptr<PvResult>(new PvResult(resBuffer)));

			// Drop the buffer if we still own it (i.e. if acquisition or push was unsuccessful, or if all was OK but it's not an image)
			if (upBuffer)
				upBuffer.reset();

			// Queue a new buffer
			pBuffer = new PvBuffer();
			pBuffer->Alloc((uint32_t)bufferSize);
			lStream->QueueBuffer(pBuffer);
		}
		else if (resRetrieve.GetCode() == PvResult::Code::TIMEOUT || ManagerFlushFlag)
		{
		}
		else
		{
			ManagerErrors.TryPush(std::unique_ptr<PvResult>(new PvResult(resRetrieve)));
			Sleep(1);
		}
	}

	//myfile.close();
		
	// Leave
	return EXIT_SUCCESS;
}

std::unique_ptr<PvBuffer> GigE_Source::GetImage()
{
	return queue.TryPop();
}

size_t GigE_Source::GetNumberOfAvailableImages()
{
	return queue.GetCount();
}

std::unique_ptr<PvResult> GigE_Source::GetError()
{
	return ManagerErrors.TryPop();
}

size_t GigE_Source::GetNumberOfErrors()
{
	return ManagerErrors.GetCount();
}

DWORD GigE_Source::WaitImages(size_t n, DWORD timeoutMilliseconds)
{
	return queue.Wait(n, timeoutMilliseconds);
}

PvResult GigE_Source::GetQueuedError()
{
	std::unique_ptr<PvResult> err;
	ManagerErrors.TryPop(err);
	if (err)
	{
		return PvResult(*err.get());
	}
	else
	{
		return PvResult(PvResult::Code::OK);
	}
	
}

PvResult GigE_Source::FlushImages()
{
	// Abort previous buffer queue
	lStream->AbortQueuedBuffers();

	// Regenerate the buffer queue
	ManagerFlushFlag = true;

	// Wait for completion
	DWORD WaitResult = WaitForSingleObject(ManagerSignal, 10000);

	// Pop all elements and free the associated buffers
	// (object deletion is handled implicitly by the unique_ptr;
	//  here we additionally added pBuffer->Free() but this is
	//  redundant)
	std::unique_ptr<PvBuffer> pBuffer;
	while (pBuffer = queue.TryPop())
	{
		pBuffer->Free();
		pBuffer.reset();
	}

	// Check if the wait was successful
	if (WaitResult != WAIT_OBJECT_0)
		return PvResult(PvResult::Code::THREAD_ERROR, PvString("Buffer manager signal timed out."));

	// Return success
	return PvResult(PvResult::Code::OK);

}


/// ------------------ JWJS -------------------------------------------------
const PvDeviceInfo * GigE_Source::SelectDevice(PvSystem * aPvSystem)
{
	const PvDeviceInfo * lDeviceInfo = NULL;
	
	if (aPvSystem != NULL)
	{
		// Get the selected device info.
		lDeviceInfo = PvSelectDevice(*aPvSystem);
	}

	return lDeviceInfo;
}
/// ------------------------


/// ------------------ JWJS -------------------------------------------------
PvDevice * GigE_Source::ConnectToDevice(const PvDeviceInfo * aDeviceInfo)
{
	PvDevice * lDevice = NULL;
	PvResult lResult;

	/// Connect to the GigE or USB3 device 
	cout << "Connecting to " << aDeviceInfo->GetDisplayID().GetAscii() << "." << endl;
	lDevice = PvDevice::CreateAndConnect(aDeviceInfo, &lResult);
	
	if (!lResult.IsOK())
	{
		cout << "Unable to connect to " << aDeviceInfo->GetDisplayID().GetAscii() << "." << endl;
	}


	

	return lDevice;
}
/// ------------------------


/// ------------------ JWJS -------------------------------------------------
PvStream * GigE_Source::OpenStream(const PvDeviceInfo * aDeviceInfo)
{
	PvStream * tempStream = NULL;
	PvResult lResult;

	// Open stream to GigE or USB3 Vision device.
	cout << "Opening stream to device." << endl;
	tempStream = PvStream::CreateAndOpen(aDeviceInfo->GetConnectionID(), &lResult);

	if (!lResult.IsOK())
	{
		cout << "Unable to open stream from device " << aDeviceInfo->GetDisplayID().GetAscii() << "." << endl;
	}

	return tempStream;
}
/// ------------------------


/// ------------------ JWJS -------------------------------------------------
/// Most of the eBUS SDK (version > 4.0) abstracts the device information so there is no need
/// to know which device type we are connecting to (GigE or USB3). However if we are working
/// with a GigE device we need to configure the destination IP address and largest packet size.
/// These requirements are taken care of below.
void GigE_Source::ConfigureStream()
{
	/// If we are working with a GigE Vision (GEV) device we configure GigE specific streaming params.
	/// Otherwise (USB3) nothing needs to be done.
	
	/// Use a dynamic cast to determine if the 'PvDevice' object represents a GigE device.
	PvDeviceGEV * lDeviceGEV = dynamic_cast<PvDeviceGEV *>(lDevice);
	
	if (lDeviceGEV != NULL)
	{
		/// If we're here we know we're working with a GigE device, so make a static cast,
		/// negotiate the packet size, and configure the device streaming destination.
		PvStreamGEV * lStreamGEV = static_cast<PvStreamGEV *>(lStream);
		lDeviceGEV->NegotiatePacketSize();
		lDeviceGEV->SetStreamDestination(lStreamGEV->GetLocalIPAddress(), lStreamGEV->GetLocalPort());
	}
}
/// ------------------------
