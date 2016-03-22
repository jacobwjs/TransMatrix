

%%
reset_all

% Identify script
name_of_script = mfilename;

% Boolean to decide if we store the resulting frames from the camera for
% each SLM projection.
STORE_FRAMES = false;

% This will contain all transmission matrix related data.
trans_matrix = struct();

% Shortcut functions
myfft2  = @(x) fftshift(fft2(ifftshift(x)));
myifft2 = @(x) fftshift(ifft2(ifftshift(x))); 

matlab_to_slm = @(img)uint8(mod(angle(img)*256/(2*pi), 256)).';
slm_to_matlab = @(img)exp(double(permute(img,[2 1 3]))*2i*pi);



%% Initialize the SLM.
% ---------------------------------------------------------------
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);
pause(0.25);
fprintf('\n');



%% Initialize the camera
% ---------------------------------------------------------------
clear vid;
display('Connecting to GiGE or USB Vision camera. Please make a choice...');
vid = camera_mex('distal','ElectronicTrigger');
%vid.ROIPosition = [352 208 608 608];
camera_frame_offsetX_pixels = 320;
camera_frame_offsetY_pixels = 120;
camera_width_pixels   = 800;
camera_height_pixels  = 800;
vid.ROIPosition = [camera_frame_offsetX_pixels camera_frame_offsetY_pixels...
                   camera_width_pixels camera_height_pixels];
camera_exposure_us = 1000;
fprintf('\n');



%% Blazed grating
% -------------------------------------------------------------------------
% Put previously calculated blazed grating on the SLM t0hat couples light
% into the fiber. These values were found by using the
% 'SLM_Phase_Mask_Software'.
zero_offset = 256;
kx_carrier_center = -101;
ky_carrier_center = 101;
blazed_grating = zeros(512, 512);
blazed_grating(zero_offset + ky_carrier_center,...
               zero_offset + kx_carrier_center) = 1;
blazed_grating = myifft2(blazed_grating);              
% blazed_grating = angle(myfft2(blazed_grating));

% Convert the phase map to 256 (8-bit) discrete values that the SLM uses to
% map voltages to phase for the given calibration.
% blazed_grating = uint8(mod(blazed_grating*256/(2*pi), 256));
blazed_grating = matlab_to_slm(blazed_grating);

disp(['Displaying blazed grating on SLM.']);
% Update the SLM.
slm.Write_img(blazed_grating);

% Find the correct order.
% Assuming 256 levels, we want a 90 phase shift, which corresponeds to
% 256/4 = 64.
blazed_grating2 = uint8(mod(double(blazed_grating) + 64, 256));
frame1 = get_frame(vid, camera_exposure_us, false);
slm.Write_img(blazed_grating2);
frame2 = get_frame(vid, camera_exposure_us, false);
imagesc(angle(fft2(frame2).*conj(fft2(frame1))));




% Now that light is diffracted into the fiber, which if the proper grating
% was selected the fiber should have light coupled into it. We use 'holography_cal_circles()'
% to find the radius of the fiber in k-space. This is proportional to the
% NA of the fiber, and gives us an impression on how many inputs we need to
% characterize the transmission properties of the fiber.
% -------------------------------------------------------------------------
disp(['Open object and reference paths for holography. Press any key to continue...']);
pause
% Get a frame from the camera.
frame = get_frame(vid, camera_exposure_us, false);


% Filter the frame.
img = double(frame)/saturation_level;
mask_hp   = ~mask_circular(size(img),[],[],200);
[X,Y] = meshgrid(1:size(img,2),1:size(img,1));
mask_diag = X<Y;
img = abs(ifft2(ifftshift2(fftshift2(fft2(img)).*(mask_diag & mask_hp))));

% Adjust levels of frame.
img_levels = quantile(img(:), [0.05,0.99]);
img = (img-img_levels(1))/(img_levels(2)-img_levels(1));
img(img>1) = 1;
img(img<0) = 0;
img = repmat(img,[1 1 3]);

% % Display it to the user.
% figure;
% subplot(2, 2, 1);
% imagesc(frame);
% subplot(2, 2, 2);
% imagesc(img);

 % Create frequency domain image. This is essentially a bunch of mapping of
 % data values to the range [0,1].
 FFT_img = db(fftshift(fft2(ifftshift(double(frame)/(numel(frame)*saturation_level)))));
 FFT_img = (FFT_img+100)/60;
 FFT_img(FFT_img>1) = 1;
 FFT_img(FFT_img<0) = 0;
 FFT_img = ind2rgb(1+round(FFT_img*255),labview);

 
% Select the region of the fiber in k-space.
fiber = holography_cal_circles(FFT_img);
 
% [x,y] values (in k-space) for creating gratings. The size (how many
% pairs) is directly related to the number of frames we need to project on the SLM
% and how many images we record (i.e. inputs to outputs).
% Note:  
% The '120' and '-20' are the ranges found from 'SLM_Phase_Mask_Software'
% slider values. That is, what slider value do we first see light diffracted into
% the fiber. The 'fiber.r1' is the radius if the k-space order representing
% frequency content of the fiber (directly related to the fiber's NA).
slm_k_scan_width = 100;
x = (zero_offset + kx_carrier_center - round(slm_k_scan_width/2)) : ...
    (zero_offset + kx_carrier_center + round(slm_k_scan_width/2));
y = (zero_offset + ky_carrier_center - round(slm_k_scan_width/2)) : ...
    (zero_offset + ky_carrier_center + round(slm_k_scan_width/2));
 
% Define scan area in k-space (SLM)
input_freq_mask = false(512,512);
input_freq_mask(y,x) = true;
input_freq_mask_linear_ind = find(input_freq_mask);
 
%% 
% Create a mask over the order selected.
dims = [vid.ROIPosition(4), vid.ROIPosition(3)];
mask_in_kspace = mask_circular(dims, fiber.xc, fiber.yc, fiber.r1);

% Retrieve data only at the selected order in kspace. This data size is
% much smaller than the image grabbed from the frame.
% Example usage:
% masked_kspace_data = mask_linear(FFT_img(:,:,1), ind);
trans_matrix.masked_FFT_output_frames = zeros(sum(sum(mask_in_kspace)), ...
                                              length(x)*length(y));




% length(x)*length(y) is the total number of inputs (SLM) project, and the
% number of outputs (camera frames) collected.
% if (STORE_FRAMES)
%     frames = zeros(vid.ROIPosition(3), ...
%                    vid.ROIPosition(4), ...
%                    length(x)*length(y));
% end


% Update the carrier used to "center" the plane waves we project into the
% fiber.
trans_matrix.zero_offset = 256;
trans_matrix.kx_carrier_center = kx_carrier_center;
trans_matrix.ky_carrier_center = ky_carrier_center;


% We capture the average of the background and calculate the stdv of the
% average. This allows us to compare a frame during the scanning to ensure
% the grating is coupling light into the fiber.
% We write a constant phase to the SLM so that no light is diffracted into
% the fiber.
slm.Write_img(uint8(255.*ones(slm.x_pixels, slm.y_pixels)));
display('Block the reference path, and leave the object path open.');
display('Press any key to continue...');
pause
% Measure the response
background_stack = double(getsnapshotse(vid, camera_exposure_us, 25));
background_mean = mean(background_stack, 4);
background_std = std(background_stack, 0, 4);
figure, imagesc(background_mean);


% 'trans_matrix.freq_mask' contains all of the points in k-space that produced gratings
% that coupled light into the fiber at an intensity greater than the
% background + 2*std. This are the inputs into the fiber.
frame_threshold = background_mean + (2 .* background_std);
trans_matrix.input_freq_masks = zeros(512, 512);

% The resulting outputs. This holds each frame reshaped into a 1-D vector,
% and each column maps to a given 'input_freq_masks'. That is SLM
% projection 'i', resulted in the column 'j' of
% 'trans_matrix.output_frames'.
if (STORE_FRAMES)
    trans_matrix.output_frames = zeros(vid.ROIPosition(3)*vid.ROIPosition(4), ...
                                       length(x)*length(y));
end

 

%% Start the measurement of inputs and outputs
% -------------------------------------------------------
display('Press any key to start the measurement...');
pause
% Create a figure that will display the scanning process.
figure;
hold on;

loop_cntr = 0;
trans_matrix.threshold_cnt = 0; 
total_frames = numel(input_freq_mask_linear_ind);

% Start the progress meter.
progress(0, total_frames);

% For the range of x and y pixels.
input_freq_mask_progress = zeros(size(input_freq_mask));
for i=1:numel(input_freq_mask_linear_ind)
    scanning_grating = zeros(512, 512);
    scanning_grating(input_freq_mask_linear_ind(i)) = 1;

    scanning_grating = myifft2(scanning_grating);
    scanning_grating = matlab_to_slm(scanning_grating);

    slm.Write_img(scanning_grating);

    subplot(2,2,1);
    imagesc(scanning_grating);
    title('Input (SLM)');

    % Grab frame
    trigger_camera(holo_params.exposure, [], 1, false);
    [frame, time(i)] = getdata(vid,1);
    
    % Process frame and store it as one of the outputs.
    % NOTE:
    % - Due to the size of inputs and outputs we mask out data in the
    %   holographic image corresponding to the order we are interested in.
    %   This converts the data to a 1-D column vector that is stored in the
    %   output matrix (Y).
    %   'camera_to_output = @(frames)mask(fftshift2(fft2(frames)),holo_params.freq.mask1);'
    trans_matrix.masked_FFT_output_frames(:, i) = camera_to_output(frame);
    
    subplot(2,2,2);
    imagesc(frame);
    title('Output (Camera)');

    % Take the FFT of the frame from the camera.
    frame_FFT = myfft2(frame);

    % Display the frame in the Fourier domain.
    subplot(2,2,3);
    imagesc(abs(db(frame_FFT)));
    title('FFT(Output)');

    % Save this point (kx, ky), which is a grating on the SLM,
    % because it coupled light into the fiber during the scan. Thus
    % it serves as an input.
    input_freq_mask_progress(input_freq_mask_linear_ind(i)) = 1;

    % Save the corresponding output.
    trans_matrix.masked_FFT_output_frames(:, i) = ...
                mask(frame_FFT, mask_in_kspace);
    % end

    subplot(2,2,4);
    imagesc(input_freq_mask_progress);
    title('kx, ky');

    drawnow;

    progress(i, total_frames);
end

hold off;

%% Create the transmission matrix - 'T'.
% 'T' is the connection between inputs (SLM phase masks) and outputs
% (frames, which in our case are mask(FFT(frame)). Y = T * X, where X
% represents our input basis (i.e. a 2D matrix where each column is a
% vector of length(total_inputs) and the value is a '1' for the grating
% placed on the SLM). Y is a 2D matrix where each column corresponds to the
% 1D vector (i.e. masked and reshaped FFT of the frame) of the output for
% the given input (SLM phase mask). To form the transmission matrix we need
% to perform T = Y * X^(-1), but because X is an identity matrix it is
% simply T = Y.
% In the above implementation Y is 'trans_matrix.masked_FFT_output_frames'.
T = trans_matrix.masked_FFT_output_frames;

% Transform output vector to input vector using Moore-Penrose
% pseudoinverse.
display('Starting pseudo-inversion of T');
tic;
%T_inv = pinv(T);
T_inv = T';
toc;

%%
% Generate an image of a spot
N = 672;
img_spot = zeros(N,N);
img_spot(round(N/2)+0,round(N/2)+20) = 1;

% We need to offset in k-space to grab the same ROI for the spot we want to
% project on the SLM.
% offset = zeros(N,N);
% offset(fiber.xc, fiber.yc) = 1;
% offset = fftshift(ifft2(ifftshift(offset)));
% offset = 1;
% shifted_spot = offset .* img_spot;

% Generate the corresponding output vector
img_spot_fft = myfft2(img_spot);

%y = img_spot_fft(square_mask_of_the_camera);
% Because we're projecting spots, we don't need to take into account the
% offset due to the carrier, so simply use the old mask without shifting.
y = mask(img_spot_fft, mask_in_kspace);

display('Calculating input for SLM to form focus spot'); 
x = T_inv * y;


% Generate SLM frame from the input vector
%spot_phase_mask_slm = angle(conj(fftshift(ifft2(ifftshift(slm_mask)))));
% spot_phase_mask_slm = angle(myifft2(slm_mask));
% spot_phase_mask_slm = uint8(mod(spot_phase_mask_slm .* 256/(2*pi), 256)).';
slm_mask = unmask(x,  input_freq_mask);
spot_phase_mask_slm = myifft2(slm_mask);
spot_phase_mask_slm = matlab_to_slm(spot_phase_mask_slm);

slm.Write_img(spot_phase_mask_slm);

%%
input_img_test = slm_to_matlab(spot_phase_mask_slm);
input_vect_test = mask(myfft2(input_img_test), input_freq_mask);
output_vect_test = T*input_vect_test;
output_img_test = myifft2(unmask(output_vect_test, mask_in_kspace));
imagesc(abs(output_img_test));
% 
% for i = 1:10
% for j = 1:20
%     N = 672;
%     img_spot = zeros(N,N);
%     img_spot(round(N/2)+j+50,round(N/2)) = 1;
%     img_spot_fft = fftshift(fft2(ifftshift(img_spot)));
%     y = mask(img_spot_fft, mask_in_kspace);
%     x = T_inv * y;
%     
%     % Generate SLM frame from the input vector
%     slm_mask = unmask(x,  trans_matrix.input_freq_masks~=0);
%     spot_phase_mask_slm = angle(fftshift(ifft2(ifftshift(slm_mask'))));
%     %spot_phase_mask_slm = angle(conj(fftshift(ifft2(ifftshift(slm_mask)))));
%     spot_phase_mask_slm = uint8(mod(spot_phase_mask_slm .* 256/(2*pi), 256));
% 
%     slm.Write_img(spot_phase_mask_slm);
%     %pause(0.25);
% end
% end

%%
frame_cnt    = 100;
% drift_frames = zeros(vid.ROIPosition(3), vid.ROIPosition(4), frame_cnt);
drift_vectors = zeros(sum(sum(mask_in_kspace)),frame_cnt);
for i=1:frame_cnt
    drift_frame = get_frame(vid, 1000, false);
    drift_vectors(:,i) = mask(myfft2(drift_frame),mask_in_kspace);
    pause(0.5);
end

% Estimation of drift and power fluctuations
disp('Drift estimation...');
reference = drift_vectors(:,1);

% figure, imagesc(reference);

[corr_cal, Rxy, ~, power_cal] = corr2c2(reference, drift_vectors(:,2:end));
pred_cal = Rxy./power_cal;

% Phase interpolation
plot(unwrap(angle(corr_cal))*180/pi);
