#include <tchar.h>
#include "diskwriter.h"


DiskWriter::DiskWriter()
{
	WriterThread = NULL;
}


DiskWriter::~DiskWriter()
{
}

bool DiskWriter::Initialize(LPCTSTR file_path, IImageQueue *source_ptr, bool pass_through_enable)
{
	// Save inputs
	pass_through = pass_through_enable;
	pSource = source_ptr;

	// Open file
	WriterFile = CreateFile(file_path, 
		                    GENERIC_WRITE,
					        FILE_SHARE_READ,
					        NULL,
							CREATE_ALWAYS,
							FILE_ATTRIBUTE_NORMAL,
							NULL);

	// Check errors
	if (WriterFile == INVALID_HANDLE_VALUE)
	{
		PushError(std::string("OpenFile failed with code ") + std::to_string(GetLastError()));
		Shutdown();
		return false;
	}

	// Start thread
	WriterThread = CreateThread(NULL, 0, WriterStaticStart, (void*)this, 0, NULL);
	if (WriterThread == NULL)
	{
		PushError(std::string("CreateThread failed with code ") + std::to_string(GetLastError()));
		Shutdown();
		return false;
	}


	// Return
	return true;
}


void DiskWriter::Shutdown()
{
	// Stop buffer Writer
	if (WriterThread != NULL)
	{
		WriterStopFlag = true;
		DWORD WaitResult = WaitForSingleObject(WriterThread, 10000);
		if (WaitResult != WAIT_OBJECT_0)
			MessageBox(NULL, _T("Writer thread does not respond."), _T("Error"), MB_OK | MB_ICONERROR);
		CloseHandle(WriterThread);
	}

	// Close file
	CloseHandle(WriterFile);

	// Empty SPSC_queue
	std::unique_ptr<PvBuffer> upBuffer;
	while (upBuffer = queue.TryPop())
		upBuffer.reset();

}

DWORD WINAPI DiskWriter::WriterStaticStart(LPVOID lpParams)
{
	DiskWriter* diskwriter = (DiskWriter*)lpParams;
	return diskwriter->WriteBuffersContinuously();
}

bool DiskWriter::WriteBuffer(std::unique_ptr<PvBuffer>& upBuffer)
{
	// Access image data
	PvImage *lImage = upBuffer->GetImage();
	uint8_t *pData = lImage->GetDataPointer();
	uint32_t ImageSize = lImage->GetImageSize();
	DWORD    BytesWritten = 0;

	// Write out
	BOOL success = WriteFile(WriterFile, pData, ImageSize, &BytesWritten, NULL);

	// Check success
	if (success)
	{
		// Increase count
		NumberOfWrittenImages++;
	}
	else {
		// Report error
		PushError(std::string("WriteFile failed with code ") + std::to_string(GetLastError()));
	}

	// Check write size
	if (BytesWritten != ImageSize)
	{
		PushError(std::string("WriteFile failed due to incomplete write."));
		success = 0;
	}

	// Return
	return success!=0;
}

DWORD DiskWriter::WriteBuffersContinuously()
{
	std::unique_ptr<PvBuffer>	upBuffer;
	DWORD						resWait;
	bool						resWrite;

	// Thread priority
	// SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);

	// Continuous loop for buffer retrieve/create
	WriterStopFlag = false;
	while (!WriterStopFlag)
	{
		// Retrieve buffer
		resWait = pSource->WaitImages(1, 1000);

		// Check if retrieve is successful
		if (resWait == WAIT_OBJECT_0)
		{
			if (upBuffer = pSource->GetImage())
			{
				// Write to disk
				resWrite = WriteBuffer(upBuffer);
				if (!resWrite)
					PushError("Write operation failed.");

				// Output queue
				if (!pass_through)
					upBuffer->Free();

				// Push to output queue
				queue.TryPush(upBuffer);

				// Report error if the push operation failed
				if (upBuffer)
					PushError("Pass-through queuing operation failed.");
			} 
			else 
			{
				// Unexpected error
				PushError("Wait operation succeeded but the queue pop operation failed.");
				Sleep(1);
			}
		}
		else if (resWait == WAIT_FAILED)
		{
			// Wait fail
			PushError("Queue wait operation failed.");
			Sleep(1);
		} 
		else if (resWait != WAIT_TIMEOUT)
		{
			// Unexpected error
			PushError("Unexpected wait error.");
			Sleep(1);
		}
	}

	// Leave
	return EXIT_SUCCESS;
}

std::unique_ptr<PvBuffer> DiskWriter::GetImage()
{
	return queue.TryPop();
}

size_t DiskWriter::GetNumberOfAvailableImages()
{
	return queue.GetCount();
}

size_t DiskWriter::GetNumberOfErrors()
{
	return WriterErrors.GetCount();
}

DWORD DiskWriter::WaitImages(size_t n, DWORD timeoutMilliseconds)
{
	return queue.Wait(n, timeoutMilliseconds);
}


void DiskWriter::PushError(std::string str)
{
	return WriterErrors.TryPush(std::unique_ptr<std::string>(new std::string(str)));
}

std::unique_ptr<std::string> DiskWriter::GetError()
{
	return WriterErrors.TryPop();
}

std::string DiskWriter::GetQueuedError()
{
	std::unique_ptr<std::string> err;
	WriterErrors.TryPop(err);
	if (err)
	{
		return std::string(*err.get());
	}
	else
	{
		return std::string("");
	}

}

bool DiskWriter::FlushImages()
{
	// Truncate the file
	DWORD resPtr = SetFilePointer(WriterFile, 0, 0, FILE_BEGIN);
	BOOL  resEnd = SetEndOfFile(WriterFile);

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

	// Check failures
	if (resPtr == INVALID_SET_FILE_POINTER)
	{
		PushError("FlushImages: SetFilePointer INVALID_SET_FILE_POINTER error.");
		return false;
	}
	if (resEnd == 0)
	{
		PushError(std::string("FlushImages: SetEndOfFile error code ") + std::to_string(GetLastError()));
		return false;
	}

	// Return success
	return true;

}