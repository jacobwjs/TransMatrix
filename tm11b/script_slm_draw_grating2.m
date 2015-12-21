% Script to display a grating on the SLM
% (for alignment)
%  - Damien Loterie (08/2015)

                          
%% Open fullscreen window
[x_slm, y_slm] = slm_size();     
addpath(dx_fullscreen_path);
dx_options = struct('monitor',      1,...
                    'screenWidth',  x_slm,...
                    'screenHeight', y_slm,...
                    'frameWidth',   x_slm,...
                    'frameHeight',  y_slm,...
                    'renderWidth',  x_slm,...
                    'renderHeight', y_slm,...
                    'renderPosX',   0,...
                    'renderPosY',   0);
d = dx_fullscreen(dx_options);

%% Create a calibration frame
% xm = round(0.75*x_slm);
% ym = center_of(y_slm);
% xm = 1920/4;
% ym = center_of(y_slm);
xm = 1275;
ym = 253;

calibration_frame = modulation_slm(x_slm, ...
                                   y_slm, ...
                                   xm, ...
                                   ym);    
                               
% Show the calibration frame
d.show(calibration_frame);