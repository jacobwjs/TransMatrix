// Code to test various aspects of the FFTW interface classes
//   - Damien Loterie (04/2015)

#ifdef _DEBUG
	#define CRTDBG_MAP_ALLOC
	#include <stdlib.h>
	#include <crtdbg.h>
#endif

#include <iostream>
#include "fftprocessor.h"
#include "fftw_wrapper_r2c.h"
#include "fftw_wrapper_c2c.h"

//int main_sub_scope()
//{
//	// Create arrays
//	float *pFloat;
//	unsigned short *pShort;
//
//	size_t numel = 100000;
//	pShort = new unsigned short[numel];
//	pFloat = new float[numel];
//
//	// Fill source with random data
//	for (size_t i = 0; i < numel; i++)
//	{
//		pShort[i] = (unsigned short)(65535 * (rand() / float(RAND_MAX)));
//	}
//
//	// Vectorized loop attempt
//	#pragma loop(ivdep)
//	for (size_t i = 0; i < numel; i++)
//		pFloat[i] = (float)pShort[i];
//
//	// Cleanup
//	delete pShort;
//	delete pFloat;
//
//	// Leave
//	return 0;
//}

//int main_sub_scope(size_t width, size_t height)
//{
//	// Performance
//	double interval;
//	LARGE_INTEGER frequency, start, end;
//	QueryPerformanceFrequency(&frequency);
//
//	// Declare source array
//	std::cout << "Preparing source data.\n";
//	unsigned short *testData;
//	//size_t width = 1312;
//	//size_t height = 1082;
//	size_t N = 100;
//	size_t rep = 10;
//	size_t numel = width * height * N;
//	testData = new unsigned short[numel];
//
//	// Fill source with random data
//	for (size_t i = 0; i < numel; i++)
//	{
//		testData[i] = (unsigned short)(65535 * (rand() / float(RAND_MAX)));
//	}
//	testData[0] = 12345;
//
//	// Create FFTW Wrapper
//	std::cout << "Preparing fftw ";
//	std::cout << width;
//	std::cout << "x";
//	std::cout << height;
//	std::cout << ".\n";
//	FFTW_Wrapper_R2C fftw;
//	fftw.Initialize(width, height);
//
//	// Transform
//	std::cout << "FFT";
//	QueryPerformanceCounter(&start);
//	for (size_t r = 0; r < rep; r++)  {
//		for (size_t i = 0; i < N; i++)
//		{
//			fftw.SetDataIn(&testData[i*width*height], width*height);
//			fftw.TransformForward();
//		}
//	}
//
//	QueryPerformanceCounter(&end);
//
//	// Performance
//	//std::cout << width;
//	std::cout << ": ";
//	interval = static_cast<double>(end.QuadPart - start.QuadPart) / frequency.QuadPart;
//	std::cout << (N*rep)/interval;
//	std::cout << " transforms/s.";
//	std::cout << "\n\n";
//	//std::cout << "\n";
//
//	// Cleanup
//	fftw.Shutdown();
//	delete testData;
//
//	// Return
//	return 0;
//}

int main_sub_test(FFTW_Wrapper_R2C &fftw)
{
	// Performance
	double interval;
	LARGE_INTEGER frequency, start, end;
	QueryPerformanceFrequency(&frequency);

	// Create arrays
	Real *testDataIn;
	Complex *testDataOut;
	size_t N = 20;
	size_t rep = 10;
	size_t numel_in = fftw.GetSizeIn();
	size_t numel_out = fftw.GetSizeOut();
	testDataIn = new Real[N*numel_in];
	testDataOut = new Complex[N*numel_out];

	// Fill source with random data
	for (size_t i = 0; i < numel_in; i++)
		testDataIn[i] = (Real)(rand() / float(RAND_MAX));

	// Transforms
	QueryPerformanceCounter(&start);
	for (size_t r = 0; r < rep; r++)  {
		for (size_t i = 0; i < N; i++)
		{
			fftw.SetDataIn(&testDataIn[i*numel_in], numel_in);
			fftw.TransformForward();
			fftw.GetDataOut(&testDataOut[i*numel_out], numel_out);
		}
	}
	QueryPerformanceCounter(&end);

	// Performance
	std::cout << "F: ";
	interval = static_cast<double>(end.QuadPart - start.QuadPart) / frequency.QuadPart;
	std::cout << (N*rep) / interval;
	std::cout << " t/s, ";

	// Transforms
	QueryPerformanceCounter(&start);
	for (size_t r = 0; r < rep; r++)  {
		for (size_t i = 0; i < N; i++)
		{
			fftw.SetDataOut(&testDataOut[i*numel_out], numel_out);
			fftw.TransformBackward();
			fftw.GetDataIn(&testDataIn[i*numel_in], numel_in);
		}
	}
	QueryPerformanceCounter(&end);

	// Performance
	std::cout << "I: ";
	interval = static_cast<double>(end.QuadPart - start.QuadPart) / frequency.QuadPart;
	std::cout << (N*rep) / interval;
	std::cout << " t/s. ";

	// Cleanup
	delete testDataIn;
	delete testDataOut;

	// Return
	return 0;
}

int main_sub_test(FFTW_Wrapper_C2C &fftw)
{
	// Performance
	double interval;
	LARGE_INTEGER frequency, start, end;
	QueryPerformanceFrequency(&frequency);

	// Create arrays
	Complex *testDataIn;
	Complex *testDataOut;
	size_t N = 20;
	size_t rep = 10;
	size_t numel_in = fftw.GetSizeIn();
	size_t numel_out = fftw.GetSizeOut();
	testDataIn = new Complex[N*numel_in];
	testDataOut = new Complex[N*numel_out];

	// Fill source with random data
	for (size_t i = 0; i < numel_in; i++)
		testDataIn[i] = Complex(rand()/float(RAND_MAX), rand()/float(RAND_MAX));

	// Transforms
	QueryPerformanceCounter(&start);
	for (size_t r = 0; r < rep; r++)  {
		for (size_t i = 0; i < N; i++)
		{
			fftw.SetDataIn(&testDataIn[i*numel_in], numel_in);
			fftw.TransformForward();
			fftw.GetDataOut(&testDataOut[i*numel_out], numel_out);
		}
	}
	QueryPerformanceCounter(&end);

	// Performance
	std::cout << "F: ";
	interval = static_cast<double>(end.QuadPart - start.QuadPart) / frequency.QuadPart;
	std::cout << (N*rep) / interval;
	std::cout << " t/s, ";

	// Transforms
	QueryPerformanceCounter(&start);
	for (size_t r = 0; r < rep; r++)  {
		for (size_t i = 0; i < N; i++)
		{
			fftw.SetDataOut(&testDataOut[i*numel_out], numel_out);
			fftw.TransformBackward();
			fftw.GetDataIn(&testDataIn[i*numel_in], numel_in);
		}
	}
	QueryPerformanceCounter(&end);

	// Performance
	std::cout << "I: ";
	interval = static_cast<double>(end.QuadPart - start.QuadPart) / frequency.QuadPart;
	std::cout << (N*rep) / interval;
	std::cout << " t/s. ";

	// Cleanup
	delete testDataIn;
	delete testDataOut;

	// Return
	return 0;
}

int main_sub_prepare()
{
	std::cout << "Setting priority.\n";
	SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);

	std::cout << "Waiting 10s.\n";
	Sleep(10*1000);

	int arr[] = {2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 24, 25, 27, 28, 30, 32, 35, 36, 40, 42, 45, 48, 49, 50, 54, 56, 60, 63, 64, 70, 72, 75, 80, 81, 84, 90, 96, 98, 100, 105, 108, 112, 120, 125, 126, 128, 135, 140, 144, 147, 150, 160, 162, 168, 175, 180, 189, 192, 196, 200, 210, 216, 224, 225, 240, 243, 245, 250, 252, 256, 270, 280, 288, 294, 300, 315, 320, 324, 336, 343, 350, 360, 375, 378, 384, 392, 400, 405, 420, 432, 441, 448, 450, 480, 486, 490, 500, 504, 512, 525, 540, 560, 567, 576, 588, 600, 625, 630, 640, 648, 672, 675, 686, 700, 720, 729, 735, 750, 756, 768, 784, 800, 810, 832, 840, 864, 875, 882, 896, 900, 928, 945, 960, 972, 980, 992, 1000, 1008, 1024, 1056};
	int N = sizeof(arr) / sizeof(arr[0]);
	for (int i = 0; i < N; i++)
	{
		std::cout << arr[i];
		std::cout << "x";
		std::cout << arr[i];
		std::cout << "...\t";

		std::cout << "R";
		FFTW_Wrapper_R2C fftw;
		fftw.Initialize(arr[i], arr[i]);
		main_sub_test(fftw);
		fftw.Shutdown();

		std::cout << "C";
		FFTW_Wrapper_C2C fftwc;
		fftwc.Initialize(arr[i], arr[i]);
		main_sub_test(fftwc);
		fftwc.Shutdown();

		std::cout << "\n";

	}

	int arr2[][2] =
	{
		{ 1312, 1082 },
		{ 1082, 1312 },
		{ 800, 1000 },
		{ 1000, 800 },
		{ 1920, 1080 },
		{ 1080, 1920 }
	};
	int N2 = sizeof(arr2) / sizeof(arr2[0]);
	for (int i = 0; i < N2; i++)
	{
		std::cout << arr2[i][0];
		std::cout << "x";
		std::cout << arr2[i][1];
		std::cout << "...\t";

		std::cout << "R";
		FFTW_Wrapper_R2C fftw;
		fftw.Initialize(arr2[i][0], arr2[i][1]);
		main_sub_test(fftw);
		fftw.Shutdown();

		std::cout << "C";
		FFTW_Wrapper_C2C fftwc;
		fftwc.Initialize(arr2[i][0], arr2[i][1]);
		main_sub_test(fftwc);
		fftwc.Shutdown();

		std::cout << "\n";
	}

	return 0;
}

//#include "gigesource.cpp"
//void main_test_interface()
//{
//	GigE_Source cam;
//	FFTProcessor fftp;
//	std::unique_ptr<std::string> pErrorStr;
//	std::unique_ptr<PvResult>    pErrorPv;
//	PvResult resCam;
//	bool resWriter;
//
//	// Initialize camera
//	std::cout << "Camera: ";
//	resCam = cam.Initialize("192.168.20.2");
//
//	std::cout << resCam.GetCodeString();
//	std::cout << ". ";
//	std::cout << resCam.GetDescription();
//	std::cout << "\n";
//
//	// Start acquisition
//	std::cout << "Acquisition: ";
//	resCam = cam.Start();
//
//	std::cout << resCam.GetCodeString();
//	std::cout << ". ";
//	std::cout << resCam.GetDescription();
//	std::cout << "\n";
//
//	// Initialize FFT processor
//	std::cout << "FFTProcessor: ";
//	std::vector<int> filter{ 1, 2, 3, 4, 5, 6, 7, 8 , 9, 10 };
//	resWriter = fftp.Initialize((IImageQueue*)&cam, 1312, 1082, filter);
//
//	if (!resWriter)
//	{
//		while (pErrorStr = fftp.GetError())
//		{
//			std::cout << *pErrorStr;
//			std::cout << "\n";
//		}
//	}
//	else
//	{
//		std::cout << "OK.\n";
//	}
//
//	// Shutdown after keypress
//	std::cin.ignore();
//
//	// Write out errors
//	std::cout << "Camera images: ";
//	std::cout << cam.GetNumberOfAvailableImages();
//	std::cout << "\n";
//	std::cout << "FFTProcessor images: ";
//	std::cout << fftp.GetNumberOfAvailableImages();
//	std::cout << "\n\n";
//	while (pErrorStr = fftp.GetError())
//	{
//		std::cout << *pErrorStr;
//		std::cout << "\n";
//	}
//	while (pErrorPv = cam.GetError())
//	{
//		std::cout << pErrorPv->GetDescription();
//		std::cout << "\n";
//	}
//
//	// Shutdown
//	cam.Stop();
//	cam.Shutdown();
//	fftp.Shutdown();
//
//	// Wait for keypress
//	std::cout << "\nDone.";
//	std::cin.ignore();
//}

void main()
{
	// 
	main_sub_prepare();

	//// Wait for keypress
	//std::cout << "\nDone.";
	//std::cin.ignore();

	//main_test_interface();

	#ifdef _DEBUG
		_CrtDumpMemoryLeaks();
	#endif
}

