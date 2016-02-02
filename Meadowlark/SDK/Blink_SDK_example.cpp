// Blink_SDK_example.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"  // Does nothing but #include targetver.h.

#include <windows.h>
#include <vector>
#include <cstdio>
#include <conio.h>
#include "Blink_SDK.h"  // Relative path to SDK header.


// -------------------- svn string compiled into code -------------------------
//lint -esym(528,Blink_SDK_example_Id)
static const char* Blink_SDK_example_Id =
  "$Id: Blink_SDK_example.cpp 531 2014-12-18 23:41:17Z ajhill $";
// ----------------------------------------------------------------------------


// ------------------------- Blink_SDK_example --------------------------------
// Simple example using the Blink_SDK DLL to send a sequence of phase targets
// to a single SLM.
// The code is written with human readability as the main goal.
// The Visual Studio 2010 sample project settings assume that Blink_SDK.lib is
// in relative path ../Blink_SDK/x64/Release.
// To run the example, ensure that Blink_SDK.dll is in the same directory as
// the Blink_SDK_example.exe.
// ----------------------------------------------------------------------------


// Typedef for the container for our phase targets.
typedef std::vector<unsigned char>  uchar_vec;

// -------------------- Consume_keystrokes ------------------------------------
// Utility function to use up the keystrokes used to interrupt the display
// loop.
// ----------------------------------------------------------------------------
static void Consume_keystrokes()
{
  // Get and throw away the character(s) entered on the console.
  int k = 0;
  while ((!k) || (k == 0xE0))  // Handles arrow and function keys.
  {
    k = _getch();
  }

  return;
}


// -------------------- Generate_ramp_image -----------------------------------
// Generates 8-wide vertical ramps, with values 0 to 223, in seven steps.
// ----------------------------------------------------------------------------
static void Generate_ramp_image(const bool increasing,
                                const size_t width,
                                const size_t height,
                                uchar_vec& pixels)
{
  // This function ASSUMES that pixels.size() is at least width * height.

  unsigned char* pix = pixels.data();

  // Since 255 is "the same" as 0, go up to 7/8 of 255. Hence, divide by 8.
  const double step = 255.0 / 8.0;

  for (size_t i = 0U; i < height; ++i)    // for each row
  {
    for (size_t j = 0U; j < width; ++j)  // for each column
    {
      size_t k = j & 0x07;
      if (!increasing)
      {
        k = 7 - k;
      }
      *pix++ = static_cast<unsigned char>(static_cast<int>(k * step + 0.5));
    }
  }

  return;
}


// -------------------- Simple_loop -------------------------------------------
// This function toggles between two ramp images, calculating the Overdrive
// frame sequence on the fly.
// ----------------------------------------------------------------------------
static bool Simple_loop(const uchar_vec& ramp1, const uchar_vec& ramp2,
                        const int board_number,
                        Blink_SDK& sdk)
{
  puts("\nSimple_loop: Press any key to exit.\n");

  bool okay      = true;
  unsigned int i = 0;

  while ((okay) && (!_kbhit()))
  {
    // Allow multiple consecutive frames of each image.
    enum { e_n_consecutive = 1 };
    unsigned int j = 0;
    const unsigned char* puc = ramp1.data();
    while ((okay) && (j < (2 * e_n_consecutive)))
    {
      okay = sdk.Write_overdrive_image(board_number, puc);
      if ((++j) == e_n_consecutive)
      {
        puc = ramp2.data();
      }
    }
    // Next two lines look a lot simpler, for case of alternating images.
    //okay = sdk.Write_overdrive_image(board_number, ramp1.data()) &&
    //       sdk.Write_overdrive_image(board_number, ramp2.data());
    ++i;
    if (!(i % 50))
    {
      printf("Completed cycles: %u\r", i);
    }
  }

  if (okay)     // Loop terminated because of a keystroke?
  {
    Consume_keystrokes();
  }

  return okay;
}


// -------------------- Precalculate_and_loop ---------------------------------
// This function toggles between two ramp images, after pre-calculating the
// Overdrive frame sequence.
// ----------------------------------------------------------------------------
static bool Precalculate_and_loop(const uchar_vec& ramp1,
                                  const uchar_vec& ramp2,
                                  const int board_number,
                                  Blink_SDK& sdk)
{
  puts("\nPrecalculate_and_loop: Press any key to exit.\n");

  // Get the SLM into the first phase state, and calculate the transient
  // frames.
  unsigned int byte_count = 0U;
  bool okay = sdk.Write_overdrive_image(board_number, ramp1.data()) &&
              sdk.Calculate_transient_frames(ramp2.data(), &byte_count);
  // Use a std::vector to store the frame sequence.
  uchar_vec transient1(byte_count);
  okay = okay && sdk.Retrieve_transient_frames(transient1.data());

  // Get the SLM into the second phase state, and calculate the transient
  // frames.
  okay = okay && sdk.Write_overdrive_image(board_number, ramp2.data()) &&
         sdk.Calculate_transient_frames(ramp1.data(), &byte_count);
  // Use another std::vector to store the frame sequence.
  uchar_vec transient2(byte_count);
  okay = okay && sdk.Retrieve_transient_frames(transient2.data());

  // Now we've completed the pre-calculation, write to the SLM.

  unsigned int i = 0;

  while ((okay) && (!_kbhit()))
  {
    // Switch from second state to first, then back again.
    okay = sdk.Write_transient_frames(board_number, transient2.data()) &&
           sdk.Write_transient_frames(board_number, transient1.data());
    ++i;
    if (!(i % 50))
    {
      printf("Completed cycles: %u\r", i);
    }
  }

  if (okay)     // Loop terminated because of a keystroke?
  {
    Consume_keystrokes();
  }

  return okay;
}


/// ------------------------------------------ JWJS ---------------------------
/// My testing routines
static bool test_write_image(const uchar_vec& ramp1,
							 const uchar_vec& ramp2,
							 const uchar_vec& calibration,
							 const int board_number,
							 Blink_SDK& sdk)
{
	puts("\nTesting write image: Press any key to exit.\n");
	fflush(NULL);

	bool okay = true;
	unsigned int i = 0;

	bool overdrive = sdk.Is_overdrive_available();
	if (overdrive)
	{
		const char* const  regional_lut_file = "slm3260_regional.txt";
		okay = sdk.Load_overdrive_LUT_file(regional_lut_file);
	}
	

	while ((okay) && (!_kbhit()))
	{
		// Allow multiple consecutive frames of each image.
		enum { e_n_consecutive = 1 };
		unsigned int j = 0;
		const unsigned char* image1 = ramp1.data();
		const unsigned char* image2 = ramp2.data();
		while ((okay) && (j < (2 * e_n_consecutive)))
		{
			//okay = sdk.Write_image(board_number, image1, 512, false, false);
			++j;
			
			okay = sdk.Write_overdrive_image(board_number, calibration.data(), 0, 0);
			//Sleep(1000);
			okay = sdk.Write_image(board_number, image2, 512, false, false);
			//Sleep(1000);
		}
		// Next two lines look a lot simpler, for case of alternating images.
		//okay = sdk.Write_overdrive_image(board_number, ramp1.data()) &&
		//       sdk.Write_overdrive_image(board_number, ramp2.data());
		++i;
		if (!(i % 50))
		{
			printf("Completed cycles: %u\r", i);
		}
	}

	if (okay)     // Loop terminated because of a keystroke?
	{
		Consume_keystrokes();
	}

	return okay;

}
/// -------------------------------------------


// -------------------- main --------------------------------------------------
// Simple example using the Blink_SDK DLL to send a sequence of phase targets
// to a single 512x512 SLM.
// This code yields a console application that will loop until the user presses
// a key.
// * If no command arguments are provided, then the application toggles between
//   two phase ramps, calculating the Overdrive frames on the fly.
// * If a 1 (digit one) is provided as an argument on the command line, then
//   the application precalculates the overdrive frame sequences, then loops
//   toggling between the two sequences. This option eliminates the Overdrive
//   calculation time from the loop.
// This application uses the first (or only) 512 SLM that it detects on the
// PCIe bus.
// ----------------------------------------------------------------------------
int main(const int argc, char* const argv[])
{
	// Decide whether we will pre-calculate the overdrive frames, or calculate
	// them on the fly.
	/*const bool pre_calculate = ((argc > 1) && (strtol(argv[1], 0, 10) == 1)) ?
	true : false;*/
	const bool pre_calculate = false;

	const int board_number = 1;

	// Construct a Blink_SDK instance with Overdrive capability.

	const unsigned int bits_per_pixel = 8U;
	const unsigned int pixel_dimension = 512U;
	const bool         is_nematic_type = true;
	const bool         RAM_write_enable = true;
	const bool         use_GPU_if_available = true;
	const char* const  regional_lut_file = "slm3260_regional.txt";

	unsigned int n_boards_found = 0U;
	bool         constructed_okay = true;

	Blink_SDK sdk(bits_per_pixel, pixel_dimension, &n_boards_found,
		&constructed_okay, is_nematic_type, RAM_write_enable, 20U,
		use_GPU_if_available, regional_lut_file);

	// Check that everything started up successfully.
	bool okay = false;
	okay = constructed_okay;
	okay = sdk.Is_slm_transient_constructed();

	// Create a calibration frame for the SLM.
	uchar_vec calibration(pixel_dimension * pixel_dimension, 255.0);

	if (okay)
	{
		enum { e_n_true_frames = 5 };
		sdk.Set_true_frames(e_n_true_frames);
		okay = sdk.Write_cal_buffer(board_number, calibration.data());
		okay = sdk.Load_linear_LUT(board_number);
		sdk.SLM_power(true);	
	}

	sdk.

	//// Create two vectors to hold values for two SLM images with opposite ramps.
	uchar_vec ramp1(pixel_dimension * pixel_dimension);
	uchar_vec ramp2(pixel_dimension * pixel_dimension);
	
	// Generate vertical ramps across the SLM images.
	Generate_ramp_image(true, pixel_dimension, pixel_dimension, ramp1);
	Generate_ramp_image(false, pixel_dimension, pixel_dimension, ramp2);



	/*okay = okay && ((pre_calculate) ?
	Precalculate_and_loop(ramp1, ramp2, board_number, sdk) :
	Simple_loop(ramp1, ramp2, board_number, sdk));*/
	test_write_image(ramp1, ramp2, calibration, board_number, sdk);
	//Sleep(1000);
	//Simple_loop(ramp1, ramp2, board_number, sdk);
	//Precalculate_and_loop(ramp1, ramp2, board_number, sdk);

	// Error reporting, if anything went wrong.
	if (!okay)
	{
		puts(sdk.Get_last_error_message());
	}
	else
	{
		sdk.SLM_power(false);
	}

	return (okay) ? EXIT_SUCCESS : EXIT_FAILURE;
}

