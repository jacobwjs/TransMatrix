#ifdef DEBUG
	#define CRTDBG_MAP_ALLOC
	#include <stdlib.h>
	#include <crtdbg.h>
#endif

#include <iostream>
#include "gigesource.cpp"
#include "diskwriter.h"


void main_sub_scope()
{
	GigE_Source cam;
	DiskWriter dw;
	std::unique_ptr<std::string> pErrorStr;
	std::unique_ptr<PvResult>    pErrorPv;
	PvResult resCam;
	bool resWriter;

	// Initialize camera
	std::cout << "Camera: ";
	resCam = cam.Initialize("192.168.20.2");

	std::cout << resCam.GetCodeString();
	std::cout << ". ";
	std::cout << resCam.GetDescription();
	std::cout << "\n";

	// Start acquisition
	std::cout << "Acquisition: ";
	resCam = cam.Start();

	std::cout << resCam.GetCodeString();
	std::cout << ". ";
	std::cout << resCam.GetDescription();
	std::cout << "\n";

	// Connect disk writer
	std::cout << "Disk writer: ";
	resWriter = dw.Initialize("C:\\video.dat", (IImageQueue*)&cam, false);
	
	if (!resWriter)
	{
		while (pErrorStr = dw.GetError())
		{
			std::cout << *pErrorStr;
			std::cout << "\n";
		}
	}
	else
	{
		std::cout << "OK.\n";
	}

	// Shutdown after keypress
	std::cin.ignore();

	// Write out errors
	std::cout << "Camera images: ";
	std::cout << cam.GetNumberOfAvailableImages();
	std::cout << "\n";
	std::cout << "DiskWriter pass-through: ";
	std::cout << dw.GetNumberOfAvailableImages();
	std::cout << "\n\n";
	while (pErrorStr = dw.GetError())
	{
		std::cout << *pErrorStr;
		std::cout << "\n";
	}
	while (pErrorPv = cam.GetError())
	{
		std::cout << pErrorPv->GetDescription();
		std::cout << "\n";
	}

	// Shutdown
	cam.Stop();
	cam.Shutdown();
	dw.Shutdown();

	// Wait for keypress
	std::cout << "\nDone.";
	std::cin.ignore();
}

void main()
{
	main_sub_scope();

	#ifdef DEBUG
		_CrtDumpMemoryLeaks();
	#endif
}

