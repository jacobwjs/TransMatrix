////////////////////////////////////////////////////////////////////////////////
// Filename: errors.h
// Basic error reporting mechanism
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _ERRORS_H_
#define _ERRORS_H_

//////////////
// INCLUDES //
//////////////
//#include <iostream>
//#include <fstream>
#include <ctime>
#include <stdio.h>
#include <windows.h>

////////////
// MACROS //
////////////
#define ReportError(...) \
	ReportErrorStamp(); \
	fprintf(stderr, __VA_ARGS__); \
	fprintf(stderr, "\n\n");

#define ReportErrorNoStamp(...) \
	fprintf(stderr, __VA_ARGS__); \
	fprintf(stderr, "\n");


//////////////
// FUNCTION //
//////////////
void ReportErrorStamp();


/////////////
// GLOBALS //
/////////////
#define ERROR_FILE "dx_engine_errors.txt"



#endif