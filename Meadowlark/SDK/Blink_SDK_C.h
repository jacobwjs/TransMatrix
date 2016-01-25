//
//:  Blink_SDK_C_wrapper for programming languages that can interface with DLLs
//
//   (c) Copyright Boulder Nonlinear Systems 2014 - 2014, All Rights Reserved.
//   (c) Copyright Meadowlark Optics 2015, All Rights Reserved.

   void* Create_SDK(unsigned int SLM_bit_depth, unsigned int SLM_resolution, unsigned int* n_boards_found, int *constructed_ok, int is_nematic_type, int RAM_write_enable, int use_GPU_if_available, int max_transient_frames, char* static_regional_lut_file);

   void Delete_SDK(void *sdk);

  
  int Is_slm_transient_constructed(void *sdk);

  
  int Write_overdrive_image(void *sdk, int board, unsigned char* target_phase, int wait_for_trigger, int external_pulse);

  int Calculate_transient_frames(void *sdk, unsigned char* target_phase, unsigned int* byte_count);

  
  int Retrieve_transient_frames(void *sdk, unsigned char* frame_buffer);

  
  int Write_transient_frames(void *sdk, int board, unsigned char* frame_buffer, int wait_for_trigger, int external_pulse);

  
  int Read_transient_buffer_size(void *sdk, char* filename, unsigned int* byte_count);

  int Read_transient_buffer(void *sdk, char* filename, unsigned int byte_count, unsigned char* frame_buffer);

  int Save_transient_frames(void *sdk, char* filename, unsigned char* frame_buffer);

  const char* Get_last_error_message(void *sdk);

  int Load_overdrive_LUT_file(void *sdk, char* static_regional_lut_file);

  
  int Load_linear_LUT(void *sdk, int board);

  
  const char* Get_version_info(void *sdk);

  
  void SLM_power(void *sdk, int power_state);

  // ----------------------------------------------------------------------------
  //  Write_image
  // ----------------------------------------------------------------------------
  
  int Write_image(void *sdk, int board, unsigned char* image, unsigned int image_size, int wait_for_trigger, int external_pulse);

  // ----------------------------------------------------------------------------
  //  Load_LUT_file
  // ----------------------------------------------------------------------------
   int Load_LUT_file(void *sdk, int board, char* LUT_file);

  // ----------------------------------------------------------------------------
  //  Compute_TF
  // ----------------------------------------------------------------------------
   int Compute_TF(void *sdk, float frame_rate);

  // ----------------------------------------------------------------------------
  //  Set_true_frames
  // ----------------------------------------------------------------------------
   void Set_true_frames(void *sdk, int true_frames);

  // ----------------------------------------------------------------------------
  //  Write_cal_buffer
  // ----------------------------------------------------------------------------
   bool Write_cal_buffer(void *sdk,
     int board, const unsigned char* buffer);