// Wrapper class which simplifies calls to FFTW for the real to complex
// transforms.
//   - Damien Loterie (04/2015)

#include "fftw_wrapper_r2c.h"

FFTW_Wrapper_R2C::FFTW_Wrapper_R2C()
{
	plan_forward = NULL;
	plan_backward = NULL;
	data_in = NULL;
	data_out = NULL;
}


FFTW_Wrapper_R2C::~FFTW_Wrapper_R2C()
{
	Shutdown();
}

void FFTW_Wrapper_R2C::Shutdown()
{
	if (plan_forward != NULL)
	{
		FFTW_PREFIX(destroy_plan(plan_forward));
		plan_forward = NULL;
	}

	if (plan_backward != NULL)
	{
		FFTW_PREFIX(destroy_plan(plan_backward));
		plan_backward = NULL;
	}

	if (data_in != NULL)
	{
		FFTW_PREFIX(free(data_in));
		data_in = NULL;
	}

	if (data_out != NULL)
	{
		FFTW_PREFIX(free(data_out));
		data_out = NULL;
	}

}

bool FFTW_Wrapper_R2C::Initialize(size_t Width, size_t Height)
{
	// Allocate arrays
	width = Width;
	height = Height;
	numel_in = height * width;
	numel_out = height * (width / 2 + 1);
	data_in  = (Real*)   FFTW_PREFIX(malloc(numel_in  * sizeof(*data_in)));
	data_out = (Complex*)FFTW_PREFIX(malloc(numel_out * sizeof(*data_out)));

	// Enable threading
	#ifdef FFTW_MULTITHREAD
		int resThread = FFTW_PREFIX(init_threads());
	#endif

	// Try to import wisdom
	FFTW_PREFIX(import_wisdom_from_filename(FFTW_WISDOM_FILE));

	// Number of threads
	#ifdef FFTW_MULTITHREAD
		FFTW_PREFIX(plan_with_nthreads(numberOfCores()));
	#endif

	// Create plan
	plan_forward = FFTW_PREFIX(plan_dft_r2c_2d(	(int)height,
												(int)width,
												data_in,
												data_out,
												FFTW_PATIENT | FFTW_DESTROY_INPUT));

	plan_backward = FFTW_PREFIX(plan_dft_c2r_2d((int)height,
												(int)width,
												data_out,
												data_in,
												FFTW_PATIENT | FFTW_DESTROY_INPUT));

	// Export wisdom back
	FFTW_PREFIX(export_wisdom_to_filename(FFTW_WISDOM_FILE));

	// Return
	bool resFinal = (plan_forward != NULL) && (plan_backward != NULL);
	#ifdef FFTW_MULTITHREAD
		resFinal &= (resThread != 0);
	#endif
	return resFinal;
}


void FFTW_Wrapper_R2C::TransformForward()
{
	FFTW_PREFIX(execute(plan_forward));
}

void FFTW_Wrapper_R2C::TransformBackward()
{
	FFTW_PREFIX(execute(plan_backward));
}

Real* FFTW_Wrapper_R2C::GetDataInPtr()
{
	return data_in;
}

Complex* FFTW_Wrapper_R2C::GetDataOutPtr()
{
	return data_out;
}

size_t FFTW_Wrapper_R2C::GetWidth()
{
	return width;
}

size_t FFTW_Wrapper_R2C::GetHeight()
{
	return height;
}

size_t FFTW_Wrapper_R2C::GetSizeIn()
{
	return numel_in;
}

size_t FFTW_Wrapper_R2C::GetSizeOut()
{
	return numel_out;
}


bool FFTW_Wrapper_R2C::GetDataIn(Real* target, size_t numel)
{
	// Check sizes
	if (numel != numel_in)
		return false;

	// Copy
	CopyMemory(target, data_in, numel*sizeof(*target));
	return true;
}

bool FFTW_Wrapper_R2C::SetDataOut(const Complex* source, size_t numel)
{
	// Check sizes
	if (numel != numel_out)
		return false;

	// Copy
	CopyMemory(data_out, source, numel*sizeof(*source));
	return true;

}

bool FFTW_Wrapper_R2C::GetDataOut(Complex* target, size_t numel)
{
	// Check sizes
	if (numel != numel_out)
		return false;

	// Copy
	CopyMemory(target, data_out, numel*sizeof(*target));
	return true;
}