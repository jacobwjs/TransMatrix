////////////////////////////////////////////////////////////////////////////////
// Filename: fftw_wrapper_c2c.h
// Wrapper class which simplifies calls to FFTW for the complex to complex
// transforms.
//   - Damien Loterie (04/2015)
////////////////////////////////////////////////////////////////////////////////
#ifndef _FFTW_WRAPPER_C2C_H_
#define _FFTW_WRAPPER_C2C_H_

//////////////
// INCLUDES //
//////////////
#include "number_of_cores.h"
#include <complex>
#include <fftw3.h>
#include <vector>
#include "fftw_wrapper_def.h"


////////////////////////////////////////////////////////////////////////////////
// Class name: FFTW_Wrapper_C2C
////////////////////////////////////////////////////////////////////////////////
class FFTW_Wrapper_C2C
{
public:
	FFTW_Wrapper_C2C();
	~FFTW_Wrapper_C2C();

	bool			Initialize(size_t, size_t); //,vector<size_t>
	void			Shutdown();

	void			TransformForward();
	void			TransformBackward();

	Complex*		GetDataInPtr();
	Complex*	    GetDataOutPtr();
	size_t			GetWidth();
	size_t			GetHeight();
	size_t			GetSizeIn();
	size_t			GetSizeOut();

	template<class T>
	bool			SetDataIn(const T*, size_t);
	bool			SetDataIn(const Complex*, size_t);
	bool			GetDataIn(Complex*, size_t);
	bool			SetDataOut(const Complex*, size_t);
	bool			GetDataOut(Complex*, size_t);

private:
	FFTW_PREFIX(plan)	plan_forward;
	FFTW_PREFIX(plan)	plan_backward;

	size_t         width;
	size_t         height;
	size_t		   numel_in;
	size_t         numel_out;

	Complex*       data_in;
	Complex*	   data_out;
};

////////////////////////////////////////////////////////////////////////////////
// METHODS
////////////////////////////////////////////////////////////////////////////////
template<class T>
bool FFTW_Wrapper_C2C::SetDataIn(const T* source, size_t numel)
{
	// Check sizes
	if (numel != numel_in)
		return false;

	// Copy
	for (size_t i = 0; i < numel; i++)
	{
		data_in[i] = Complex((Real)source[i], 0);
	}
	return true;
}

#endif
