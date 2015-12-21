% Script to display a linear grating on the SLM (for alignment)
%  - Damien Loterie (08/2015)

% Cleanup other fullscreens
s = whos;
for i=1:numel(s)
    if strcmp(s(i).class,'dx_fullscreen')
       try %#ok<TRYNC>
           eval([s(i).name '.quit;']); 
           eval(['delete(' s(i).name '); clear ' s(i).name ';']); 
       end
    end
end

% Calibration (configure fullscreen, camera and holography)
% Load proximal-side calibration data
slm_params = slm_getcal();

% Create a calibration frame
calibration_frame = modulation_slm(slm_params.ROI(3), ...
                                   slm_params.ROI(4), ...
                                   slm_params.freq.x+0.75*slm_params.freq.r1, ...
                                   slm_params.freq.y); %...
                           % .* uint8(slm_params.fiber.mask2);                         
                          
                           
% Fullscreen startup parameters
[x_slm, y_slm] = slm_size();

% Open fullscreen window
addpath(dx_fullscreen_path);
dx_options = struct('monitor',      1,...
                    'screenWidth',  x_slm,...
                    'screenHeight', y_slm,...
                    'frameWidth',   slm_params.ROI(3),...
                    'frameHeight',  slm_params.ROI(4),...
                    'renderWidth',  slm_params.ROI(3),...
                    'renderHeight', slm_params.ROI(4),...
                    'renderPosX',   slm_params.ROI(1),...
                    'renderPosY',   slm_params.ROI(2));
d = dx_fullscreen(dx_options);

% Show the calibration frame
d.show(calibration_frame);