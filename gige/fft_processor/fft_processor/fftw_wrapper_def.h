////////////////////////////////////////////////////////////////////////////////
// Filename: fftw_wrapper_def.h
// Definitions for the FFT classes. Allows to switch multithreading on or off,
// and allows switching between float or double precision.
//   - Damien Loterie (04/2015)
////////////////////////////////////////////////////////////////////////////////
#ifndef _FFTW_WRAPPER_DEF_H_
#define _FFTW_WRAPPER_DEF_H_

//////////////
// INCLUDES //
//////////////
#include <fftw3.h>

/////////////////
// DEFINITIONS //
/////////////////
// Comment or uncomment to choose float or double precision respectively
#define FFTW_PRECISION_DOUBLE
#define FFTW_MULTITHREAD

///////////////
// AUTOMATIC //
///////////////
#ifdef FFTW_PRECISION_DOUBLE
	typedef double Real;
	#pragma comment(lib, "libfftw3-3.lib")
	#define FFTW_PREFIX(arg)fftw_ ## arg
	#define FFTW_MATLAB_CLASS mxDOUBLE_CLASS
	#ifdef FFTW_MULTITHREAD
		#define FFTW_WISDOM_FILE "./fftw_wisdom_mt.dat"
	#else
		#define FFTW_WISDOM_FILE "./fftw_wisdom_st.dat"
	#endif
#else
typedef float Real;
	#define FFTW_PRECISION_FLOAT
	#pragma comment(lib, "libfftw3f-3.lib")
	#define FFTW_PREFIX(arg)fftwf_ ## arg
	#define FFTW_MATLAB_CLASS mxSINGLE_CLASS
	#ifdef FFTW_MULTITHREAD
	#define FFTW_WISDOM_FILE "./fftwf_wisdom_mt.dat"
	#else
	#define FFTW_WISDOM_FILE "./fftwf_wisdom_st.dat"
	#endif
#endif

typedef FFTW_PREFIX(complex) Complex;

#endif