// Test code for the GigE_Source class.
//  - Damien Loterie (11/2014)

#ifdef DEBUG
	#define CRTDBG_MAP_ALLOC
	#include <stdlib.h>
	#include <crtdbg.h>
#endif

#include <iostream>
#include "gigesource.h"




void main_sub_scope()
{
	GigE_Source cam;

	PvResult res = cam.Initialize("192.168.20.2");

	if (!res.IsSuccess())
	{
		std::cout << "Error: Camera not initialized\n";
		return;
	}

	std::cout << res.GetCodeString();
	std::cout << "\n";
	std::cout << res.GetDescription();

	std::cout << cam.Start();

	// Shutdown after keypress
	std::cin.ignore();
	cam.Shutdown();

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

