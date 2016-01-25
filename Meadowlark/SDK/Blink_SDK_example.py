# Example usage of Blink_SDK_C.dll
# Meadowlark Optics Spatial Light Modulators
# March 2 2015

import os
from ctypes import *
from scipy import misc
from time import sleep

# Load the DLL
# Blink_SDK_C.dll, Blink_SDK.dll, FreeImage.dll and wdapi1021.dll
# should all be located in the same directory as the program referencing the
# library
cdll.LoadLibrary("Blink_SDK_C")
slm_lib = CDLL("Blink_SDK_C")

# Path to this example and the files it references
# Remember to escape the backslash
path = "C:\\Program Files\\Meadowlark Optics\\OverDrive Plus SDK"

# Basic parameters for calling Create_SDK
bit_depth = c_uint(8)
slm_resolution = c_uint(512)
num_boards_found = c_uint(0)
constructed_okay = c_bool(0)
is_nematic_type = c_bool(1)
RAM_write_enable = c_bool(1)
use_GPU = c_bool(1)
max_transients = c_uint(20)

# OverDrive Plus parameters
lut_file = c_char_p(os.path.join(path, "SLM_lut.txt"))

# Basic SLM parameters
true_frames = c_int(3)

# Blank calibration image
cal_image = misc.imread(os.path.join(path, "512white.bmp"), flatten = 0)

# Arrays for image data
ramp_0 = misc.imread(os.path.join(path, "ramp_0_512.bmp"), flatten = 0)
ramp_1 = misc.imread(os.path.join(path, "ramp_1_512.bmp"), flatten = 0)

# Call the Create_SDK constructor
# Returns a handle that's passed to subsequent SDK calls
sdk = slm_lib.Create_SDK(bit_depth, slm_resolution, byref(num_boards_found), 
                         byref(constructed_okay), is_nematic_type, 
                         RAM_write_enable, use_GPU, max_transients, lut_file)

if not constructed_okay:
    print "Blink SDK was not successfully constructed"
    # Python ctypes assumes the return value is always int
    # We need to tell it the return type by setting restype
    slm_lib.Get_last_error_message.restype = c_char_p
    print slm_lib.Get_last_error_message(sdk)

    # Always call Delete_SDK before exiting
    slm_lib.Delete_SDK(sdk)
else:
    print "Blink SDK was successfully constructed"
    print "Found %s SLM controller(s)" % num_boards_found.value

    # Set the basic SLM parameters
    slm_lib.Set_true_frames(sdk, true_frames)
    # A blank calibration image must be loaded to the SLM controller
    slm_lib.Write_cal_buffer(sdk, 1, cal_image)
    # A linear LUT must be loaded to the controller for OverDrive Plus
    slm_lib.Load_linear_LUT(sdk, 1)

    # Turn the SLM power on
    slm_lib.SLM_power(sdk, c_bool(1))

    # Loop between our ramp images
    for i in range(0, 1000):
        slm_lib.Write_overdrive_image(sdk, 1, ramp_0.ctypes.data_as(POINTER(c_ubyte)), 0)
        sleep(0.025) # This is in seconds
        slm_lib.Write_overdrive_image(sdk, 1, ramp_1.ctypes.data_as(POINTER(c_ubyte)), 0)
        sleep(0.025) # This is in seconds

    # Always call Delete_SDK before exiting
    slm_lib.Delete_SDK(sdk)