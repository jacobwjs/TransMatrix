//
//:  C++ interface to Blink_SDK DLL.
//
//   (c) Copyright Boulder Nonlinear Systems 2014 - 2014, All Rights Reserved.
//   (c) Copyright Meadowlark Optics 2015, All Rights Reserved.

#ifndef BLINK_SDK_H_
#define BLINK_SDK_H_

#ifdef BLINK_SDK_EXPORTS
#define BLINK_SDK_API __declspec(dllexport)
#else
#define BLINK_SDK_API
#endif

#include <cstddef>
class Blink_SDK_impl;


/// @file
///
/// Interface to the Blink SDK.
///
/// @section usage Using the Blink OverDrive SDK
///
/// @subsection overview General Overview
/// All but two overdrive functions return a @c bool value to indicate success
/// or failure. When a function returns @c false, call Get_last_error_message() to
/// get a text string with information about the failure.
/// There are effectively three modes of operation using this SDK with overdrive.
/// @subsection sub1 Calculate and send frames to SLM
/// <<>>
/// @subsection sub2 Pre-calculate frames and store in memory before sending to SLM
/// <<>>
/// @subsection sub3 Load/save pre-calculated frames to files
/// <<>>


class BLINK_SDK_API Blink_SDK
{
public:

  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  /// @brief Constructor for the Blink SDK.
  ///
  /// @param SLM_bit_depth             Options are currently @c 8 or @c 16
  /// @param SLM_resolution            Options are currently @c 256 or @c 512
  ///                                  (square SLM assumed).
  /// @param n_boards_found            Initial value ignored; set to the
  ///                                  number of SLM boards found that have
  ///                                  the requested resolution.
  /// @param constructed_ok            @c true if all elements of the SDK were
  ///                                  properly constructed, else @c false.
  /// @param is_nematic_type           @c true for a nematic SLM (usual case);
  ///                                  @c false for FLC.
  /// @param RAM_write_enable          @c true for writing to RAM (usual case)
  ///                                  @c false for slower writes.
  /// @param use_GPU_if_available      @c true to use a GPU; @c false to use
  ///                                  a CPU for OverDrive calculations. If
  ///                                  @c true is provided, but no GPU is
  ///                                  available, then a CPU will be used.
  /// @param max_transient_frames      The maximum number of transient frames
  ///                                  calculated by the OverDrive Plus
  ///                                  algorithm.
  /// @param static_regional_lut_file  Regional LUT file; used for OverDrive
  ///                                  calculations.
  ///
  /// @sa Get_last_error_message, Is_slm_transient_constructed
  // -------------------------------------------------------------------------
  Blink_SDK(unsigned int SLM_bit_depth,
            unsigned int SLM_resolution,
            unsigned int* n_boards_found,
            bool *constructed_ok,
            bool is_nematic_type = true,
            bool RAM_write_enable = true,
            bool use_GPU_if_available = true,
            size_t max_transient_frames = 20U,
            const char* static_regional_lut_file = 0);


  // -------------------------------------------------------------------------
  // Destructor
  // -------------------------------------------------------------------------
  /// @brief Destructor for the Blink SDK.
  // -------------------------------------------------------------------------
  ~Blink_SDK();


  // -------------------------------------------------------------------------
  // Is_overdrive_available
  // -------------------------------------------------------------------------
  /// @brief Returns @c true if overdrive functionality is built into this
  /// version of the SDK, otherwise @c false.
  // -------------------------------------------------------------------------
  bool Is_overdrive_available() const;


  // -------------------------------------------------------------------------
  // Is_slm_transient_constructed
  // -------------------------------------------------------------------------
  /// @brief Returns the state of the overdrive wrapper class responsible for
  /// transient frame calculations.
  ///
  /// @return @c true if there were no internal errors constructing the
  /// SLM_transient class, otherwise @c false.
  /// @sa Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Is_slm_transient_constructed() const;


  // -------------------------------------------------------------------------
  // Write_overdrive_image
  // -------------------------------------------------------------------------
  /// @brief Writes an image to the SLM using the intermediate transient
  /// frames calculated with overdrive.
  ///
  /// @param  board        Index of the board with the required SLM. The index
  ///                      is 1-based (not 0-based).
  /// @param target_phase  Image of the target phase for the SLM.
  /// @param wait_for_trigger    If supported by hardware, this enables use of
  ///                            an external trigger to load images to the SLM.
  /// @param external_pulse      Enables an external pulse on the last transient
  ///                            frame.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Write_overdrive_image(int board,
                             const unsigned char* target_phase,
                             bool wait_for_trigger = false,
                             bool external_pulse = false);


  // -------------------------------------------------------------------------
  // Calculate_transient_frames
  // -------------------------------------------------------------------------
  /// @brief Calculates the series of frames to be sent to the SLM to
  /// transition to @c target_phase using overdrive.
  ///
  /// @param target_phase  Image of the target phase for the SLM. Phase values
  ///                      from 0 to 1.0 correspond to pixel value 0 and 255.
  /// @param byte_count    Set by this function to the number of bytes
  ///                      required to store the sequence of frames.
  ///                      This parameter must not be NULL. Initial value is
  ///                      ignored.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Calculate_transient_frames(const unsigned char* target_phase,
                                  unsigned int* byte_count);


  // -------------------------------------------------------------------------
  // Retrieve_transient_frames
  // -------------------------------------------------------------------------
  /// @brief Retrieves the data for a previously-calculated series of frames.
  /// Typically a call to this function is preceded by a call to
  /// Calculate_transient_frames.
  ///
  /// @param frame_buffer  Pointer to a caller-provided memory area of
  ///                      sufficient size to store the frame data.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa CalculateTransientFrames, Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Retrieve_transient_frames(unsigned char* frame_buffer);


  // -------------------------------------------------------------------------
  // Write_transient_frames
  // -------------------------------------------------------------------------
  /// @brief Writes the sequence of frames in @c frame_buffer to the SLM.
  ///
  /// @param board               Index of the board with the required SLM. The
  ///                            index is 1-based (not 0-based).
  /// @param frame_buffer        Contains the sequence of frames to be written
  ///                            to the SLM.
  /// @param max_display_frames  0 to display all frames in the sequence;
  ///                            non-zero to display no more than @c
  ///                            max_display_frames of the frames in @c
  ///                            frame_buffer.
  /// @param wait_for_trigger    If supported by hardware, this enables use of
  ///                            an external trigger to load images to the SLM.
  /// @param external_pulse      Enables an external pulse on the last transient
  ///                            frame.
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Write_transient_frames(int board,
                              const unsigned char* frame_buffer,
                              unsigned int max_display_frames = 0U,
                              bool wait_for_trigger = false,
                              bool external_pulse = false);


  // -------------------------------------------------------------------------
  // Read_transient_buffer_size
  // -------------------------------------------------------------------------
  /// @brief Reads the file header and retrieves the number of bytes to be
  /// allocated for reading the frame.
  ///
  /// Call this function before calling ReadTransientBuffer, and allocate the
  /// appropriate buffer size for subsequent use by ReadTransientBuffer().
  ///
  /// @param filename   Name of the file containing transient data.
  /// @param byte_count Set by this function to the number of bytes to be
  ///                   allocated. This parameter must not be NULL. Initial
  ///                   value is ignored.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa ReadTransientBuffer(), Get_last_error_message().
  // -------------------------------------------------------------------------
  bool Read_transient_buffer_size(const char*   filename,
                                  unsigned int* byte_count);


  // -------------------------------------------------------------------------
  // Read_transient_buffer
  // -------------------------------------------------------------------------
  /// @brief Reads the series of transient frames from the file into
  /// @c frame_buffer, which must point to sufficient memory to hold the
  /// entire buffer.
  ///
  /// Call ReadTransientBufferSize() to determine the required buffer size.
  /// Pass the size of FrameBuffer in ByteCount (for error checking).
  ///
  /// @param filename     Name of the file containing transient data.
  /// @param byte_count   Number of bytes that have been allocated in
  ///                     frame_buffer.
  /// @param frame_buffer Buffer to hold the frame data read from the file.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Read_transient_buffer_size(), Get_last_error_message().
  // -------------------------------------------------------------------------
  bool Read_transient_buffer(const char*    filename,
                             unsigned int   byte_count,
                             unsigned char* frame_buffer);


  // -------------------------------------------------------------------------
  // Save_transient_frames
  // -------------------------------------------------------------------------
  /// @brief Writes transient frame data to a file.
  ///
  /// @param filename      Name of the file to be written.
  /// @param frame_buffer  Frame data to be written to the file.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message.
  // -------------------------------------------------------------------------
  bool Save_transient_frames(const char*          filename,
                             const unsigned char* frame_buffer);


  // -------------------------------------------------------------------------
  // Get_last_error_message
  // -------------------------------------------------------------------------
  /// @brief Returns a pointer to the string corresponding to the last error
  /// condition detected. If no error has been detected, the string is
  /// "Blink SDK: No error".
  ///
  /// @return Null-terminated C string.
  // -------------------------------------------------------------------------
  const char* Get_last_error_message() const;


  // -------------------------------------------------------------------------
  // Load_overdrive_LUT_file
  // -------------------------------------------------------------------------
  /// @brief Loads a new set of LUT data for transient calculations.
  ///
  /// @param static_regional_lut_file  File with regional LUT data.
  ///
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message
  // -------------------------------------------------------------------------
  bool Load_overdrive_LUT_file(const char* static_regional_lut_file);


  // -------------------------------------------------------------------------
  // Load_linear_LUT
  // -------------------------------------------------------------------------
  /// @brief Forces a linear LUT to be loaded to the SLM.
  ///
  /// @param board  Index of the board with the required SLM. The index is
  ///               1-based (not 0-based).
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message
  // -------------------------------------------------------------------------
  bool Load_linear_LUT(int board);


  // -------------------------------------------------------------------------
  // Get_bits_per_pixel
  // -------------------------------------------------------------------------
  /// @brief Returns the number of bits for each pixel on the SLM (typically
  /// 8 or 16).
  ///
  /// @return Number of bits per pixel.
  // -------------------------------------------------------------------------
  size_t Get_bits_per_pixel() const;


  // -------------------------------------------------------------------------
  // Get_version_info
  // -------------------------------------------------------------------------
  /// @brief Returns a pointer to the string with version information for this
  /// SDK.
  ///
  /// @return Null-terminated C string.
  // -------------------------------------------------------------------------
  const char* Get_version_info() const;


  // -------------------------------------------------------------------------
  // SLM_power
  // -------------------------------------------------------------------------
  /// @brief Turns the SLM on or off for @c board.
  ///
  /// @param power_state  @c true for ON, @c false for OFF
  /// @param board        Index of the board with the required SLM. The index
  ///                     is 1-based (not 0-based).
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message
  // -------------------------------------------------------------------------
  bool SLM_power(int board, bool power_state);


  // -------------------------------------------------------------------------
  // SLM_power
  // -------------------------------------------------------------------------
  /// @brief Turns all SLMs on or off.
  ///
  /// @param power_state  @c true for ON, @c false for OFF
  // -------------------------------------------------------------------------
  void SLM_power(bool power_state);


  // -------------------------------------------------------------------------
  //  Write_image
  // -------------------------------------------------------------------------
  /// @brief Write a non-overdrive image to the SLM controlled by @c board.
  ///
  /// @param  board       Index of the board with the required SLM. The index
  ///                     is 1-based (not 0-based).
  /// @param  image       The image to write to the SLM.
  /// @param  image_size  SLM width or height (a square SLM is assumed).
  /// @param wait_for_trigger    If supported by hardware, this enables use of
  ///                            an external trigger to load images to the SLM.
  /// @param external_pulse      Enables an external pulse when the image is 
  ///                            written to the SLM.
  ///
  /// @return @c true if the image was written successfully, otherwise @c
  /// false.
  /// @sa Get_last_error_message
  // -------------------------------------------------------------------------
  bool Write_image(int board, const unsigned char* image,
                   unsigned int image_size,
                   bool wait_for_trigger = false,
                   bool external_pulse = false);


  // -------------------------------------------------------------------------
  // Load_LUT_file
  // -------------------------------------------------------------------------
  /// @brief Loads the specified LUT file to the SLM.
  ///
  /// @param  board    Index of the board with the required SLM. The index is
  ///                  1-based (not 0-based).
  /// @param LUT_file  Fully-qualified path to LUT file.
  /// @return @c true if there were no errors, otherwise @c false.
  /// @sa Get_last_error_message
  // -------------------------------------------------------------------------
  bool Load_LUT_file(int board, const char* LUT_file);


  // -------------------------------------------------------------------------
  // Compute_TF
  // -------------------------------------------------------------------------
  ///
  /// @param  frame_rate
  /// @return @c true if there were no errors, otherwise @c false.
  // -------------------------------------------------------------------------
  int Compute_TF(float frame_rate);


  // -------------------------------------------------------------------------
  // Set_true_frames
  // -------------------------------------------------------------------------
  ///
  /// @param  true_frames
  /// @return
  // -------------------------------------------------------------------------
  void Set_true_frames(int true_frames);


  // -------------------------------------------------------------------------
  // Set_coverglass_flipping
  // -------------------------------------------------------------------------
  ///
  /// @param  board     Index of the board with the required SLM. The index is
  ///                   1-based (not 0-based).
  /// @param  flipping
  /// @return @c true if there were no errors, otherwise @c false.
  // -------------------------------------------------------------------------
  bool Set_coverglass_flipping(int board, bool flipping);


  // -------------------------------------------------------------------------
  // Set_correction_type
  // -------------------------------------------------------------------------
  ///
  /// @param  board     Index of the board with the required SLM. The index is
  ///                   1-based (not 0-based).
  /// @param  WFC
  /// @return @c true if there were no errors, otherwise @c false.
  // -------------------------------------------------------------------------
  bool Set_correction_type(int board, bool WFC);


  // -------------------------------------------------------------------------
  //  Write_cal_buffer
  // -------------------------------------------------------------------------
  ///
  /// @param  board     Index of the board with the required SLM. The index is
  ///                   1-based (not 0-based).
  /// @param  buffer
  /// @return @c true if there were no errors, otherwise @c false.
  // -------------------------------------------------------------------------
  bool Write_cal_buffer(int board, const unsigned char* buffer);


  // -------------------------------------------------------------------------
  //  Select_cal_frame
  // -------------------------------------------------------------------------
  ///
  /// @param  board     Index of the board with the required SLM. The index is
  ///                   1-based (not 0-based).
  /// @param  frame
  /// @return @c true if there were no errors, otherwise @c false.
  // -------------------------------------------------------------------------
  bool Select_cal_frame(int board, int frame);


  // Additional include for BNS/MLO internal use.
#ifdef BNS_MLO_INTERNAL_USE
#include "Blink_SDK_internal.h"
#endif


private:

  Blink_SDK_impl* m_sdk_pimpl;

  // Copy constructor and assignment operator are declared private so that
  // they cannot be used outside the class.
  Blink_SDK(const Blink_SDK& r);
  const Blink_SDK& operator=(const Blink_SDK& r);

}; //lint !e1712  No use for default constructor.

#endif   // #ifndef BLINK_SDK_H_
