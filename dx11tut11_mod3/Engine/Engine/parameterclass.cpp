////////////////////////////////////////////////////////////////////////////////
// Filename: parameterclass.cpp
// Class containing all the parameters necessary to run the DirectX engine and 
// put frames at the right place and time on the screen.
//  - Damien Loterie (01/2014)
////////////////////////////////////////////////////////////////////////////////
#include "parameterclass.h"
#include "errors.h"
#include "ini.h"

ParameterClass::ParameterClass()
{
	// Default values for all parameters are zeros
	ZeroMemory(this, sizeof(ParameterClass));

	// Other default values
	signalNow = true;
	#ifdef ENABLE_TRIGGERING
		pulseHighTime = 0.001;
		pulseLowTime  = 1e-6;
		pulseNumber = 1;
	#endif
}


// INI parser
bool ParameterClass::Parse(char* path)
{
	// Parse INI file
	int result = 0;
	result = ini_parse(path, ValueHandler, this);
	if (!(result==0))
	{
		ReportError("INI parser failed with code %d.", result)
		return false;
	}

	// Check correct configuration
	result = CheckAndComplete();
	if (!result)
	{
		ReportError("Some configuration parameters have incorrect values.")
		return false;
	}

	// Return
	return true;
}

// Variable checker
bool ParameterClass::CheckAndComplete()
{
	if (!(
		(adapter >= 0) &&
		(monitor >= 0) &&
		(screenWidth > 0) &&
		(screenHeight > 0) &&
		(bufferFrameSize > 0)//&&
		//(renderPosX >= 0) &&
		//(renderPosY >= 0)
		))
	{
		return false;
	}

	// Use defaults for frame size if both values are zero. Otherwise, check that both values are nonzero.
	if (frameWidth == 0 && frameHeight == 0)
	{
		frameWidth = screenWidth;
		frameHeight = screenHeight;
	}
	else if (!(frameWidth != 0 && frameHeight != 0))
	{
		return false;
	}

	// Use defaults for frame size if both values are zero. Otherwise, check that both values are nonzero.
	if (renderWidth == 0 && renderHeight == 0)
	{
		renderWidth = frameWidth;
		renderHeight = frameHeight;
	}
	else if (!(renderWidth != 0 && renderHeight != 0))
	{
		return false;
	}

	// Success
	return true;

}

// Handler to parse each field from the INI
int ParameterClass::ValueHandler(void* user,
	                             const char* section,
								 const char* name,
	                             const char* value)
{
	// Init
	bool result = false;

	// Prepare field processor macro
	#define  FIELD(parameterName, readOnly, cType, mType, numberOfElements)					\
	if (strcmp(name, #parameterName)==0)													\
	{																						\
		result = SetParameterFromChar(&(((ParameterClass*)user)->parameterName), value);	\
	} else																					\

	// Load fields
	#include "parameters.def"

	// Handle case of an unknown parameter name
	{
		ReportError("Encountered unknown parameter name '%s' during INI parsing.", name);
		return false;
	}

	// Leave (and warn for failure)
	return result;
}

// Character to number conversion overloads
bool ParameterClass::SetParameterFromChar(double* target, const char* valuePtr)
{
	// Conversion
	char* endPtr;
	double number;
	number = std::strtod(valuePtr, &endPtr);

	// Check success
	if (endPtr == valuePtr) {
		return false;
	}
	else {
		*target = number;
		return true;
	}
}
bool ParameterClass::SetParameterFromChar(int* target, const char* valuePtr)
{
	// Conversion
	char* endPtr;
	int number;
	number = std::strtol(valuePtr, &endPtr, 10);

	// Check success
	if (endPtr == valuePtr) {
		return false;
	}
	else {
		*target = number;
		return true;
	}
}
bool ParameterClass::SetParameterFromChar(bool* target, const char* valuePtr)
{
	// Check true/false
	if (_stricmp(valuePtr, "true")==0)
	{
		*target = true;
		return true;
	}
	else if (_stricmp(valuePtr, "false")==0)
	{
		*target = false;
		return true;
	}

	// Conversion
	char* endPtr;
	bool result;
	result = (std::strtol(valuePtr, &endPtr, 10))!=0;

	// Check success
	if (endPtr == valuePtr) {
		return false;
	}
	else {
		*target = result;
		return true;
	}
}
bool ParameterClass::SetParameterFromChar(SYSTEMTIME* target, const char* valuePtr)
{
	// Check true/false
	ReportError("Parsing of SYSTEMTIME structure is not implemented");
	return false;
}