% Example usage of Blink_SDK_C.dll
% Meadowlark Optics Spatial Light Modulators
% March 28 2015

% INPUTS:
% 'run_test_patterns' => [bool] Dictates if the SLM should run
%                          through a series of test patterns to verify the 
%                          device is working.
% OUTPUT:
% 'sdk' => A lib pointer to the Meadowlark SDK.
% -------------------------------------------------------------------------
function [sdk] = Initialize_meadowlark_slm(run_test_patterns)

% Load the DLL
% Blink_SDK_C.dll, Blink_SDK.dll, FreeImage.dll and wdapi1021.dll
% should all be located in the same directory as the program referencing the
% library. Matlab only supports C-style headers so this is a 'sanitized' version of
% the normal header file
loadlibrary('Blink_SDK_C.dll', 'Blink_SDK_C_matlab.h');

% Basic parameters for calling Create_SDK
bit_depth = 8;
slm_resolution = 512;
num_boards_found = libpointer('uint32Ptr', 0);
constructed_okay = libpointer('int32Ptr', 0);
is_nematic_type = 1;
RAM_write_enable = 1;
use_GPU = 1;
max_transients = 20;

% Matlab does not change the current working directory when making function
% calls. We don't want to give absolute paths to the regional LUT below, so
% we change directories to the location of this function, and load the
% appropriate file.
full_path = which(mfilename); % Full path to this file (inclusive).
dir_path  = fileparts(full_path); % Only want the directory path.

% OverDrive Plus Parameters full path
if (isempty(dir_path))
    lut_file = 'slm3260_regional.txt';
else
    lut_file = [dir_path, filesep, 'slm3260_regional.txt'];
end
fprintf('Loading Overdrive Plus Regional LUT...\n\t%s\n', lut_file);

% Basic SLM parameters
true_frames = 3;

% Blank calibration image
cal_image = imread('512white.bmp');

% Arrays for image data
ramp_0 = imread('ramp_0_512.bmp');
ramp_1 = imread('ramp_1_512.bmp');

sdk = calllib('Blink_SDK_C',...
    'Create_SDK',...
    bit_depth,...
    slm_resolution,...
    num_boards_found,...
    constructed_okay,...
    is_nematic_type,...
    RAM_write_enable,...
    use_GPU,...
    max_transients,...
    lut_file);

if constructed_okay.value == 0
    disp('Blink SDK was not successfully constructed');
    disp(calllib('Blink_SDK_C', 'Get_last_error_message', sdk));
    calllib('Blink_SDK_C', 'Delete_SDK', sdk);
else
    disp('Meadowlark Blink SDK was successfully constructed');
    fprintf('Found %u SLM controller(s)\n', num_boards_found.value);
    % Set the basic SLM parameters
    calllib('Blink_SDK_C', 'Set_true_frames', sdk, true_frames);
    % A blank calibration file must be loaded to the SLM controller
    calllib('Blink_SDK_C', 'Write_cal_buffer', sdk, 1, cal_image);
    % A linear LUT must be loaded to the controller for OverDrive Plus
    calllib('Blink_SDK_C', 'Load_linear_LUT', sdk, 1);
    
    % Turn the SLM power on
    calllib('Blink_SDK_C', 'SLM_power', sdk, 1);
    
    if (run_test_patterns)
        disp('SLM successfully initialized... running test patterns');
        % Loop between our ramp images
        for n = 1:50
            calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, ramp_0, 0, 1);
            pause(0.025) % This is in seconds
            calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, ramp_1, 0, 1);
            pause(0.025) % This is in seconds
        end
    else
        disp('SLM successfully initialized');
    end
    
    
end

end

