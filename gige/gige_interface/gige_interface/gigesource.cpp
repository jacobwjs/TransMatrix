// Class that will connect to the camera, listen for incoming frames, and store
// them in memory. This happens in a dedicated high-priority thread, to avoid
// frame drops. There is a basic error reporting mechanism.
//  - Damien Loterie (11/2014)



#include "gigesource.h"


GigE_Source::GigE_Source()
{
	ManagerThread = NULL;
	ManagerSignal = NULL;

	/// -------------- JWJS ------------------
	lDevice = NULL;
	lStream = NULL;
	/// ---------------------
}


GigE_Source::~GigE_Source()
{

}

PvResult GigE_Source::Initialize(const PvString camera_identifier)
{
	/// Initialize results variable
	PvResult result;
	const PvDeviceInfo *lDeviceInfo = NULL;

	
	/// Find device
	/// ------------------------------------------------------------------------------------ 
	PvSystem * lPvSystem = new PvSystem;
	lDeviceInfo = SelectDevice(lPvSystem);

	
	if (lDeviceInfo != NULL)
	{
		/// Basic error checking for the IP configuration.
		if (!lDeviceInfo->IsConfigurationValid())
		{
			return PvResult(PvResult::Code::NETWORK_ERROR, PvString("ERROR. The camera's IP configuration is invalid."));
		}

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

		/// Manage buffers.
		/// --------------------------------------------------------------------------------
		lDeviceParams = lDevice->GetParameters();
		
		
	}

	/*
	PvSystem lSystem;
	PvCheck(lSystem.FindDevice(*camera_identifier, &lDeviceInfo), Shutdown(););

	// Check IP configuration
	if (!lDeviceInfo->IsConfigurationValid())
		return PvResult(PvResult::Code::NETWORK_ERROR, PvString("The camera's IP configuration is invalid."));

	// Connect to device
	PvCheck(lDevice.Connect(lDeviceInfo->GetIPAddress()), Shutdown(););

	// Negotiate streaming packet size
	PvCheck(lDevice.NegotiatePacketSize(), Shutdown(););

	// Get parameter array
	lDeviceParams = lDevice.GetGenParameters();

	////////////
	// STREAM //
	////////////
	// Open stream
	PvCheck(lStream.Open(lDeviceInfo->GetIPAddress(), 0, 0, "", PVSTREAM_NUM_BUFFERS), Shutdown(););

	// Configure the device IP destination to the stream
	PvCheck(lDevice.SetStreamDestination(lStream.GetLocalIPAddress(), lStream.GetLocalPort()), Shutdown(););

	*/


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
			MessageBox(NULL, "Manager thread does not respond.", "Error", MB_OK | MB_ICONERROR);
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

	// Start acquisition
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


PvStream * GigE_Source::OpenStream(const PvDeviceInfo * aDeviceInfo)
{
	PvStream * lStream = NULL;
	PvResult lResult;

	// Open stream to GigE or USB3 Vision device.
	cout << "Opening stream to device." << endl;
	lStream = PvStream::CreateAndOpen(aDeviceInfo->GetConnectionID(), &lResult);

	if (!lResult.IsOK())
	{
		cout << "Unable to open stream from device " << aDeviceInfo->GetDisplayID().GetAscii() << "." << endl;
	}

	return lStream;
}

/// Most of the eBUS SDK (version > 4.0) abstracts the device information so there is no need
/// to know which device type we are connecting to (GigE or USB3). However if we are working
/// with a GigE device we need to configure the destination IP address and largest packet size.
/// These requirements are taken care of below.
void GigE_Source::ConfigureStream(PvDevice * aDevice, PvStream * aStream)
{
	/// If we are working with a GigE Vision (GEV) device we configure GigE specific streaming params.
	/// Otherwise (USB3) nothing needs to be done.
	
	/// Use a dynamic cast to determine if the 'PvDevice' object represents a GigE device.
	PvDeviceGEV * lDeviceGEV = dynamic_cast<PvDeviceGEV *>(aDevice);
	
	if (lDeviceGEV != NULL)
	{
		/// If we're here we know we're working with a GigE device, so make a static cast,
		/// negotiate the packet size, and configure the device streaming destination.
		PvStreamGEV * lStreamGEV = static_cast<PvStreamGEV *>(aStream);
		lDeviceGEV->NegotiatePacketSize();
		lDeviceGEV->SetStreamDestination(lStreamGEV->GetLocalIPAddress(), lStreamGEV->GetLocalPort());
	}
}
