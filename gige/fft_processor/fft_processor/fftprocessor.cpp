// The FFTProcessor class takes live Fourier transforms of images in an input
// queue.
//   - Damien Loterie (04/2015)

#include "fftprocessor.h"

FFTProcessor::FFTProcessor()
{
	ProcessorThread = NULL;
}


FFTProcessor::~FFTProcessor()
{
}

bool FFTProcessor::Initialize(IImageQueue *source_ptr, size_t width, size_t height, vector<int> filter)
{
	// Save inputs
	pSource = source_ptr;

	// Create FFTW object
	if (!fft_r2c.Initialize(width, height))
	{
		PushError(std::string("FFTW initialization failed."));
		return false;
	}

	// Save filter indices
	indices = filter;

	// Start thread
	ProcessorThread = CreateThread(NULL, 0, ProcessorStaticStart, (void*)this, 0, NULL);
	if (ProcessorThread == NULL)
	{
		PushError(std::string("CreateThread failed with code ") + std::to_string(GetLastError()));
		Shutdown();
		return false;
	}


	// Return
	return true;
}


void FFTProcessor::Shutdown()
{
	// Stop buffer Writer
	if (ProcessorThread != NULL)
	{
		ProcessorStopFlag = true;
		DWORD WaitResult = WaitForSingleObject(ProcessorThread, 10000);
		if (WaitResult != WAIT_OBJECT_0)
			MessageBox(NULL, "Writer thread does not respond.", "Error", MB_OK | MB_ICONERROR);
		CloseHandle(ProcessorThread);
	}

	// Cleanup FFTW
	fft_r2c.Shutdown();
	FFTW_PREFIX(cleanup_threads());
	FFTW_PREFIX(cleanup());

	// Empty SPSC_queue
	queue.Clear();
}

DWORD WINAPI FFTProcessor::ProcessorStaticStart(LPVOID lpParams)
{
	FFTProcessor* processor = (FFTProcessor*)lpParams;
	return processor->ProcessBuffersContinuously();
}

bool FFTProcessor::ProcessBuffer(std::unique_ptr<PvBuffer>& upBuffer)
{
	// Access image data
	PvImage *lImage = upBuffer->GetImage();
	uint8_t *pData = lImage->GetDataPointer();
	uint32_t ImageSizeBytes = lImage->GetImageSize();
	uint32_t ImageBpp = lImage->GetBitsPerPixel();
	size_t   ImageNumel = (ImageSizeBytes * 8) / ImageBpp;
		
	// Load data
	bool resCopy;
	switch (ImageBpp)
	{
	case 8:
		resCopy = fft_r2c.SetDataIn(pData, ImageNumel);
		break;
	case 16:
		resCopy = fft_r2c.SetDataIn((uint16_t *)pData, ImageNumel);
		break;
	default:
		PushError(std::string("ProcessBuffer failed: cannot copy the data to the FFTW buffer (unsupported bit depth)"));
		return false;
		break;
	}
	if (!resCopy)
	{
		PushError(std::string("ProcessBuffer failed: cannot copy the data to the FFTW buffer (ImageSize=")
			+ std::to_string(ImageNumel)
			+ std::string("; Buffer=")
			+ std::to_string(fft_r2c.GetSizeIn())
			+ std::string(")"));
		return false;
	}

	// Fourier transform
	fft_r2c.TransformForward();

	// Fetch output
	Complex* full_output = fft_r2c.GetDataOutPtr();
	size_t   full_output_max = fft_r2c.GetSizeOut();

	// Extract part of the output
	unique_ptr<FFTExtract> extract(new FFTExtract());
	extract->coefficients.reserve(indices.size());
	extract->timestamp = upBuffer->GetTimestamp();

	for (size_t i = 0; i < indices.size(); i++) {
		if (indices[i] >= 0)
		{
			if (indices[i] < full_output_max) {
				extract->coefficients.push_back(full_output[indices[i]]);
			}
			else
			{
				PushError(std::string("ProcessBuffer failed: filter indices out of range."));
				return false;
			}
		}
		else
		{
			if (-indices[i] < full_output_max) {
				extract->coefficients.push_back(conj(full_output[-indices[i]]));
			}
			else
			{
				PushError(std::string("ProcessBuffer failed: filter indices out of range."));
				return false;
			}
		}
	}

	// Push output to the queue
	queue.TryPush(extract);
	if (extract)
	{
		PushError(std::string("ProcessBuffer failed: could not push the transformed data to the output stack."));
		return false;
	}

	// Return
	return true;
}

DWORD FFTProcessor::ProcessBuffersContinuously()
{
	std::unique_ptr<PvBuffer> upBuffer;
	DWORD					  resWait;
	bool					  resProcess;

	// Thread priority
	//SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);

	// Continuous loop for buffer retrieve/create
	ProcessorStopFlag = false;
	while (!ProcessorStopFlag)
	{
		// Retrieve buffer
		resWait = pSource->WaitImages(1, 1000);

		// Check if retrieve is successful
		if (resWait == WAIT_OBJECT_0)
		{
			if (upBuffer = pSource->GetImage())
			{
				// Process buffer
				resProcess = ProcessBuffer(upBuffer);
				if (!resProcess)
					PushError("Process operation failed.");
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

std::unique_ptr<FFTExtract> FFTProcessor::GetImage()
{
	return queue.TryPop();
}

size_t FFTProcessor::GetNumberOfAvailableImages()
{
	return queue.GetCount();
}

size_t FFTProcessor::GetNumberOfErrors()
{
	return Errors.GetCount();
}

DWORD FFTProcessor::WaitImages(size_t n, DWORD timeoutMilliseconds)
{
	return queue.Wait(n, timeoutMilliseconds);
}


void FFTProcessor::PushError(std::string str)
{
	return Errors.TryPush(std::unique_ptr<std::string>(new std::string(str)));
}

std::unique_ptr<std::string> FFTProcessor::GetError()
{
	return Errors.TryPop();
}

std::string FFTProcessor::GetQueuedError()
{
	std::unique_ptr<std::string> err;
	Errors.TryPop(err);
	if (err)
	{
		return std::string(*err.get());
	}
	else
	{
		return std::string("");
	}

}

bool FFTProcessor::FlushImages()
{
	// Clear queue
	queue.Clear();

	// Return success
	return true;

}