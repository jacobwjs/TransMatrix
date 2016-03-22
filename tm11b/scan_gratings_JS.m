

%%
reset_all

% Identify script
name_of_script = mfilename;

% Boolean to decide if we store the resulting frames from the camera for
% each SLM projection.
STORE_FRAMES = false;

% This will contain all transmission matrix related data.
trans_matrix = struct();



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
vid.ROIPosition = [384 152 672 672];
camera_exposure_us = 1000;
fprintf('\n');



%% Blazed grating
% -------------------------------------------------------------------------
% Put previously calculated blazed grating on the SLM t0hat couples light
% into the fiber. These values were found by using the
% 'SLM_Phase_Mask_Software'.
zero_offset = 256;
kx_carrier_center = 101;
ky_carrier_center = -101;
blazed_grating = zeros(512, 512);
blazed_grating(zero_offset + kx_carrier_center,...
                       zero_offset + ky_carrier_center) = 1;
blazed_grating = angle(fftshift(fft2(ifftshift(blazed_grating))));

% Convert the phase map to 256 (8-bit) discrete values that the SLM uses to
% map voltages to phase for the given calibration.
blazed_grating = uint8(mod(blazed_grating*256/(2*pi), 256));

disp(['Displaying blazed grating on SLM.']);
% Update the SLM.
slm.Write_img(blazed_grating);


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
x = (zero_offset + kx_carrier_center - round(fiber.r1/2)) : ...
    (zero_offset + kx_carrier_center + round(fiber.r1/2));
y = (zero_offset + ky_carrier_center - round(fiber.r1/2)) : ...
    (zero_offset + ky_carrier_center + round(fiber.r1/2));
 
 
%% 
% Create a mask over the order selected.
dims = [vid.ROIPosition(3), vid.ROIPosition(4)];
mask_in_kspace = mask_circular(dims, fiber.xc, fiber.yc, fiber.r1);
% Get the indices of the mask.
ind = mask_to_indices(mask_in_kspace);
% Retrieve data only at the selected order in kspace. This data size is
% much smaller than the image grabbed from the frame.
% Example usage:
% masked_kspace_data = mask_linear(FFT_img(:,:,1), ind);
trans_matrix.masked_FFT_output_frames = zeros(length(ind), ...
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
total_frames = length(x);

% Start the progress meter.
progress(0, total_frames);

% For the range of x and y pixels.
for i=1:length(x)
    % Update the progress of the scan.
    loop_cntr = loop_cntr + 1;
     
    for j = 1:length(y)
        kx_coord = x(j);
        ky_coord = y(i);
        
        scanning_grating = zeros(512, 512);
        %scanning_grating(x(i),y(j)) = 1;
        scanning_grating(kx_coord,ky_coord) = 1;
        
        % Add in the carrier since we want to scan around the carrier we
        % found above.
%         scanning_grating(zero_offset + kx_carrier_center,...
%                          zero_offset + ky_carrier_center) = 1;
        
        scanning_grating = angle(fftshift(fft2(ifftshift(scanning_grating))));
        % Convert the phase map to 256 (8-bit) discrete values that the SLM uses to
        % map voltages to phase for the given calibration.
        scanning_grating = uint8(mod(scanning_grating*256/(2*pi), 256));
        
        slm.Write_img(scanning_grating);
        
        subplot(2,2,1);
        imagesc(scanning_grating);
        title('Input (SLM)');
        
        subplot(2,2,2);
        frame = get_frame(vid, camera_exposure_us, false);
        imagesc(frame);
        title('Output (Camera)');
        
        % Take the FFT of the frame from the camera.
        frame_FFT = fftshift(fft2(ifftshift(frame)));
        
        % Display the frame in the Fourier domain.
        subplot(2,2,3);
        imagesc(abs(db(frame_FFT)));
        title('FFT(Output)');
        
        % Check if this frame couple light into the fiber and produced a
        % frame of higher intensity than the background_average + 2*stdv.
       % if (sum(sum(frame)) > sum(sum(frame_threshold)))
            % Update the counter.
            trans_matrix.threshold_cnt = trans_matrix.threshold_cnt + 1; 
            
            % Save this point (kx, ky), which is a grating on the SLM,
            % because it coupled light into the fiber during the scan. Thus
            % it serves as an input.
            trans_matrix.input_freq_masks(kx_coord, ky_coord) = 1;
            
            % Save the corresponding output.
            if (STORE_FRAMES)
                trans_matrix.output_frames(:, trans_matrix.threshold_cnt) = ...
                    reshape(frame', vid.ROIPosition(3)*vid.ROIPosition(4), 1);
            end
            trans_matrix.masked_FFT_output_frames(:, trans_matrix.threshold_cnt) = ...
                    mask(frame_FFT, mask_in_kspace);
       % end
        
        subplot(2,2,4);
        imagesc(trans_matrix.input_freq_masks);
        title('kx, ky');
        
        drawnow;
        
%         if (STORE_FRAMES)
%             frames(:,:,i) = frame;
%         end
    end
    
    progress(loop_cntr, total_frames);
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

% Generate an image of a spot
N = 672;
img_spot = zeros(N,N);
img_spot(round(N/2)+20,round(N/2)) = 1;

% We need to offset in k-space to grab the same ROI for the spot we want to
% project on the SLM.
% offset = zeros(N,N);
% offset(fiber.xc, fiber.yc) = 1;
% offset = fftshift(ifft2(ifftshift(offset)));
% offset = 1;
% shifted_spot = offset .* img_spot;

% Generate the corresponding output vector
img_spot_fft = fftshift(fft2(ifftshift(img_spot)));

%y = img_spot_fft(square_mask_of_the_camera);
% Because we're projecting spots, we don't need to take into account the
% offset due to the carrier, so simply use the old mask without shifting.
y = mask(img_spot_fft, mask_in_kspace);

% Transform output vector to input vector using Moore-Penrose
% pseudoinverse.
display('Starting pseudo-inversion of T');
tic;
% T_inv = pinv(T);
T_inv = T';
toc;

display('Calculating input for SLM to form focus spot'); 
x = T_inv * y;

% Generate SLM frame from the input vector
slm_mask = unmask(x,  trans_matrix.input_freq_masks~=0);
%spot_phase_mask_slm = angle(conj(fftshift(ifft2(ifftshift(slm_mask)))));
spot_phase_mask_slm = angle(fftshift(ifft2(ifftshift(slm_mask))));
spot_phase_mask_slm = uint8(mod(spot_phase_mask_slm .* 256/(2*pi), 256));

slm.Write_img(spot_phase_mask_slm);


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

% frame_cnt    = 100;
% drift_frames = zeros(vid.ROIPosition(3), vid.ROIPosition(4), frame_cnt);
% for i=1:frame_cnt
%     drift_frames(:,:,i) = get_frame(vid, 1000, false);
%     pause(0.5);
% end
% 
% % Estimation of drift and power fluctuations
% disp('Drift estimation...');
% reference = drift_frames(:,:,1);
% 
% figure, imagesc(reference);
% 
% [corr_cal, Rxy, ~, power_cal] = corr2c2(reference, drift_frames(:,:,2:end));
% pred_cal = Rxy./power_cal;
% 
% % Phase interpolation
% sc = csapi(time_cal, corr_cal);
% 
% comp = fnval(sc, time);
% comp_cal = fnval(sc, time_cal);
% 
% comp     = comp     ./ abs(comp);
% comp_cal = comp_cal ./ abs(comp_cal)

figure;
while 1
    frame = get_frame(vid, camera_exposure_us, false);
    subplot(2,2,1)
    imagesc(frame)
    axis fill
    subplot(2,2,2)
    imagesc(db(fftshift(fft2(ifftshift(frame)))));
    axis fill
    drawnow
end
