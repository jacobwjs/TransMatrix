////////////////////////////////////////////////////////////////////////////////
// Filename: fftw_wrapper_r2c.h
// Wrapper class which simplifies calls to FFTW for the real to complex
// transforms.
//   - Damien Loterie (04/2015)
////////////////////////////////////////////////////////////////////////////////
#ifndef _FFTW_WRAPPER_R2C_H_
#define _FFTW_WRAPPER_R2C_H_

//////////////
// INCLUDES //
//////////////
#include "number_of_cores.h"
#include <complex>
#include <fftw3.h>
#include <vector>
#include "fftw_wrapper_def.h"


////////////////////////////////////////////////////////////////////////////////
// Class name: FFTW_Wrapper_R2C
////////////////////////////////////////////////////////////////////////////////
class FFTW_Wrapper_R2C
{
public:
	FFTW_Wrapper_R2C();
	~FFTW_Wrapper_R2C();

	bool			Initialize(size_t, size_t); //,vector<size_t>
	void			Shutdown();
	
	void			TransformForward();
	void			TransformBackward();

	Real*			GetDataInPtr();
	Complex*	    GetDataOutPtr();
	size_t			GetWidth();
	size_t			GetHeight();
	size_t			GetSizeIn();
	size_t			GetSizeOut();

	template<class T>
	bool			SetDataIn(const T*, size_t);
	bool			GetDataIn(Real*, size_t);
	bool			SetDataOut(const Complex*, size_t);
	bool			GetDataOut(Complex*, size_t);

private:
	FFTW_PREFIX(plan)	plan_forward;
	FFTW_PREFIX(plan)	plan_backward;

	size_t         width;
	size_t         height;
	size_t		   numel_in;
	size_t         numel_out;

	Real*          data_in;
	Complex*	   data_out;
};

////////////////////////////////////////////////////////////////////////////////
// METHODS
////////////////////////////////////////////////////////////////////////////////
template<class T>
bool FFTW_Wrapper_R2C::SetDataIn(const T* source, size_t numel)
{
	// Check sizes
	if (numel != numel_in)
		return false;

	// Copy
	std::copy(&source[0], &source[numel], data_in);
	return true;
}

#endif
