////////////////////////////////////////////////////////////////////////////////
// Filename: fftprocessor.h
// The FFTProcessor class takes live Fourier transforms of images in an input
// queue.
//   - Damien Loterie (04/2015)
////////////////////////////////////////////////////////////////////////////////
#ifndef _FFTPROCESSOR_H_
#define _FFTPROCESSOR_H_

//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include <string>
#include <PvBuffer.h>
#include "spsc_queue.h"
#include "iimagequeue.h"
#include "fftw_wrapper_r2c.h"
using namespace std;

////////////////////////////////////////////////////////////////////////////////
// Class name: FFTProcessor
////////////////////////////////////////////////////////////////////////////////
struct FFTExtract
{
	vector<Complex>     coefficients;
	uint64_t			timestamp;
};

class FFTProcessor
{
public:
	FFTProcessor();
	~FFTProcessor();

	bool	Initialize(IImageQueue*, size_t, size_t, vector<int>);
	void	Shutdown();

	bool						FlushImages();
	unique_ptr<FFTExtract>	    GetImage();
	unique_ptr<string>			GetError();
	size_t						GetNumberOfAvailableImages();
	size_t						GetNumberOfWrittenImages();
	size_t						GetNumberOfErrors();
	DWORD						WaitImages(size_t, DWORD);


private:
	IImageQueue					*pSource;
	SPSC_Queue<FFTExtract>		queue;

	vector<int>					indices;
	FFTW_Wrapper_R2C			fft_r2c;

	HANDLE						ProcessorThread;
	bool volatile				ProcessorStopFlag = false;
	bool						ProcessBuffer(unique_ptr<PvBuffer>&);
	DWORD						ProcessBuffersContinuously();
	static DWORD WINAPI			FFTProcessor::ProcessorStaticStart(LPVOID);

	SPSC_Queue<string>			Errors;
	void						PushError(string);
	string						GetQueuedError();
};

#endif
