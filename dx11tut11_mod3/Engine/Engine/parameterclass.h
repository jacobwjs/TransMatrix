////////////////////////////////////////////////////////////////////////////////
// Filename: graphicsclass.h
// Class containing all the parameters necessary to run the DirectX engine and 
// put frames at the right place and time on the screen.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#ifndef _PARAMETERCLASS_H_
#define _PARAMETERCLASS_H_


//////////////
// INCLUDES //
//////////////
#include <windows.h>
#include <cstdlib>


#define PARAMETER_DEFAULT_FILE "dx_engine_config.ini"

////////////////////////////////////////////////////////////////////////////////
// Class name: ParameterClass
////////////////////////////////////////////////////////////////////////////////
class ParameterClass
{
public:
	// Declare parameter values
	#define  FIELD(name, readOnly, cType, mType, numberOfElements) cType name;
	#include "parameters.def"

	// Functions
	ParameterClass();
	bool Parse(char*);

private:
	bool CheckAndComplete();
	static int  ValueHandler(void*, const char*, const char*, const char*);
	static bool SetParameterFromChar(double*		target, const char* value);
	static bool SetParameterFromChar(int*			target, const char* value);
	static bool SetParameterFromChar(bool*			target, const char* value);
	static bool SetParameterFromChar(SYSTEMTIME*    target, const char* value);
};

#endif