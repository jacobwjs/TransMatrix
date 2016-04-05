% Script to measure a transmission matrix.
% v8:  vsync-triggering is now handled by the DAQ card
% v8c: replaced camera interface with custom C++ code
% v9:  real-time disk writing and Fourier transform
% v10: SLM in configuration without beamsplitter (for correlation)
% - Damien Loterie (08/2015)

close all
clear all
clc



%% Initialize
% Cleanup
reset_all;

DEBUG = false;

% Shortcut functions
myfft2  = @(x) fftshift(fft2(ifftshift(x)));
myifft2 = @(x) fftshift(ifft2(ifftshift(x))); 
radians_to_8bit_phase = @(img)uint8(mod(angle(img)*256/(2*pi), 256));
bits_to_radians = @(img) (exp(1i.*double(img)/255*2*pi));


% Identify script
name_of_script = mfilename;

%% Initialize the hardware (SLM + Camera)
% -------------------------------------------------------------------------
% Initialize the SLM
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);

% Initialize camera
display('Initializing the camera...');
vid = camera_mex('distal', 'ElectronicTrigger');
% Define the ROI in the camera
camera_frame_offsetX_pixels = 384;
camera_frame_offsetY_pixels = 220;
camera_width_pixels   = 544;
camera_height_pixels  = 544;
vid.ROIPosition = [camera_frame_offsetX_pixels camera_frame_offsetY_pixels...
                   camera_width_pixels camera_height_pixels];
camera_exposure_us = 5000;
fprintf('Camera exposure set to %d usecs\n\n', camera_exposure_us);



%% Calibration (configure fullscreen, camera and holography)
% -------------------------------------------------------------------------
% Define proximal-side calibration data
slm_params = struct();
slm_params.ROI = [0 0 slm.x_pixels slm.y_pixels];
slm_params.exposure = [];
% Assume the image of the fiber facet on the SLM is centered.
slm_params.fiber.x = 257;
slm_params.fiber.y = 257;

% DC in k-space (assuming a 512x512 grid)
x_offset = 256;
y_offset = 256;
% Carrier frequency in k-space
freq_x = -111;
freq_y = 111;
slm_params.freq.x = x_offset + freq_x;
slm_params.freq.y = y_offset + freq_y;
slm_params.freq.r1 = 70;
slm_params.freq.r2 = slm_params.freq.r1;
slm_params = recalculate_square_masks(slm_params);
% FIXME:
% slm_params.freq.mask1 = mask_circular([slm_params.ROI(4),slm_params.ROI(3)],...
%     slm_params.freq.x,...
%     slm_params.freq.y,...
%     slm_params.freq.r1*2);
% 
% slm_params.freq.mask1c = mask_circular([slm_params.ROI(4),slm_params.ROI(3)],...
%     [],...
%     [],...
%     slm_params.freq.r1*2);
% 
% slm_params.freq.mask2 = mask_circular([slm_params.ROI(4),slm_params.ROI(3)],...
%     slm_params.freq.x,...
%     slm_params.freq.y,...
%     slm_params.freq.r2*2);
% 
% slm_params.freq.mask2c = mask_circular([slm_params.ROI(4),slm_params.ROI(3)],...
%     [],...
%     [],...
%     slm_params.freq.r2*2);


% Define holography parameters
% -------------------------------------------------------------------------
holo_params = struct();
% The holography parameters are defined in the same ROI of the camera
% frame, as well as the exposure value.
holo_params.ROI = vid.ROIPosition;
holo_params.exposure = camera_exposure_us;

% The center (pixel number x-axis and y-axis) of the fiber in the frame
% retrieved from the camera.
holo_params.fiber.x = center_of(holo_params.ROI(3)); 
holo_params.fiber.y = center_of(holo_params.ROI(4));

% The center (pixel number x-axis and y-axis) of the selected order [k-space].
% holo_params.freq.x = 456; Wrong order for CW alignment  
% holo_params.freq.y = 407;   
holo_params.freq.x = 115;   
holo_params.freq.y = 155; 

% The radius of the selected order in pixel count [k-space].
holo_params.freq.r1 = 70;  
holo_params.freq.r2 = slm_params.freq.r1; % Make them equal for the time being.

holo_params.fiber.mask2 = mask_circular([holo_params.ROI(4) holo_params.ROI(3)],...
                                        holo_params.fiber.x, holo_params.fiber.y, 0.4*holo_params.ROI(3));

                                    
holo_params = recalculate_square_masks(holo_params);
% % FIXME:  
% holo_params.freq.mask1 = mask_circular([holo_params.ROI(4),holo_params.ROI(3)],...
%     holo_params.freq.x,...
%     holo_params.freq.y,...
%     holo_params.freq.r1*2);
% 
% holo_params.freq.mask1c = mask_circular([holo_params.ROI(4),holo_params.ROI(3)],...
%     [],...
%     [],...
%     holo_params.freq.r1*2);
% 
% holo_params.freq.mask2 = mask_circular([holo_params.ROI(4),holo_params.ROI(3)],...
%     holo_params.freq.x,...
%     holo_params.freq.y,...
%     holo_params.freq.r2*2);
% 
% holo_params.freq.mask2c = mask_circular([holo_params.ROI(4),holo_params.ROI(3)],...
%     [],...
%     [],...
%     holo_params.freq.r2*2);



% Check grid size
fft_size_check(slm_params.ROI(3));
if slm_params.ROI(3)~=slm_params.ROI(4)
    fft_size_check(slm_params.ROI(4));
end

% Output
disp(['Input mask:  ' int2str(sum(slm_params.freq.mask1(:))) ' pixels (r=' int2str(slm_params.freq.r1) ')']);
disp(['Input ROI:   ' int2str(slm_params.ROI(3)) 'x' int2str(slm_params.ROI(4))]);

% Create a calibration frame
calibration_frame = modulation_slm(slm_params.ROI(3), ...
                                   slm_params.ROI(4), ...
                                   slm_params.freq.x, ...
                                   slm_params.freq.y);
                      
% Show calibration frame
display('Writing calibration frame to SLM...');
slm.Write_img(calibration_frame);


disp(['Output mask: ' int2str(sum(holo_params.freq.mask1(:))) ' pixels (r=' int2str(holo_params.freq.r1) ')']);
disp(['Output ROI:  ' int2str(holo_params.ROI(3)) 'x' int2str(holo_params.ROI(4))]);
disp(['Exposure:    ' num2str(round(holo_params.exposure)) 'us']);

% Check grid size
fft_size_check(holo_params.ROI(3));
if holo_params.ROI(3)~=holo_params.ROI(4)
    fft_size_check(holo_params.ROI(4));
end

% Check exposure
if holo_params.exposure<1000
   str = input('The exposure is too low. Do you want to continue? ','s');
    if ~strcmpi(str,'y')
       error('Aborted.')
    end
end



%% Definitions
% [INPUT BASIS]
% [RECONSTRUCTION]
% [OUTPUT BASIS]
script_tm10_basis;

% Basis size info
disp(['Basis size:  ' num2str(sum(sum(holo_params.freq.mask1))) ' pixels by ' num2str(input_size(2)) ' frames']);

% [MEASUREMENT SEQUENCE]
% Define an interleave pattern to put calibration frames between the basis vectors
interleave_factor = 3;
interleave_indexes = interleave_calibration(interleave_factor, input_size(2));
number_of_frames = numel(interleave_indexes);
calibration_frames = (interleave_indexes==0);

% Function that generates the interleaved sequence
sequence_function = @(n)interleave_calibration(interleave_factor, ...
                                               input_size(2), ...
                                               @(n)input_to_slm(input_function(n)), ...
                                               calibration_frame, ...
                                               n);

%% Pre-measurement check to see if the right order is selected
slm.Write_img(calibration_frame);
response_original = get_frame(vid, holo_params.exposure, false);

calibration_frame2 = uint8(mod(double(calibration_frame)+64,256));
slm.Write_img(calibration_frame2);
response_shifted = get_frame(vid, holo_params.exposure, false);

figure;
imagesc(angle(fft2(response_original).*conj(fft2(response_shifted))));
title('Order verification');  

% % Calculate average measured phase shift.
% response_diff = conj(fft2s(response_original)).*fft2s(response_shifted);
% phase_average = sum(sum(abs(response_diff).^2 .* exp(1i*angle(response_diff))));
% phase_average = exp(1i*angle(phase_average));
% 
% % Check if this was the right order.
% %order_check = abs(phase_average-exp(0.5i*pi)) < abs(phase_average-exp(-0.5i*pi));
% order_check = imag(phase_average)>0;
% if ~order_check
%     error('The wrong holographic order has been selected.');
% end


%% Check the mask in Fourier domain to ensure it selects the entire selected
%% holographic order.
figure;
hold on;
subplot(2,2,1);
imagesc(db(double(fftshift2(fft2(response_original))).*holo_params.freq.mask1));
title('Mask verification');
subplot(2,2,2);
imagesc(db(double(fftshift2(fft2(response_original))).*~holo_params.freq.mask1));
title('Mask verification');
hold off;



%% Confirmation to continue with the measurement.
disp('Press a key to continue...');
pause;


%% Measurement
% Background correction (i.e. removal of the contribution from the
% reference arm).
slm.Write_img(255.*ones(size(calibration_frame2),'like',calibration_frame2));
n_bg = 20;
frame_bg = zeros(holo_params.ROI(4), holo_params.ROI(3), n_bg);
for i=1:n_bg
    frame_bg(:,:,i) = get_frame(vid, holo_params.exposure, false);
end
frame_bg = mean(double(frame_bg),3);
background_vector = mask(fftshift2(fft2(frame_bg)),holo_params.freq.mask1);

% Configure camera for fixed exposure
set(vid.source, 'ExposureMode', 'Timed');
set(vid.source, 'ExposureTime', holo_params.exposure);
start(vid);
    
% Timing
tic_global = tic;

if (DEBUG)
    % Create a figure that will display the scanning process.
    figure;
    hold on;
end

% Begine the measurement of the inputs (X) to outputs (Y).
data_rec = zeros(sum(sum(holo_params.freq.mask1)),number_of_frames,'like',1i);
time = zeros(1,number_of_frames);
progress(0,number_of_frames);
for i=1:number_of_frames
    % Display pattern
    slm.Write_img(sequence_function(i));
    %pause(0.050);
      
    % Grab frame
    trigger_camera(holo_params.exposure, [], 1, false);
    [frame, time(i)] = getdata(vid,1);
    
    % Process frame and store
    data_rec(:,i) = camera_to_output(frame);
     
    % Display figures of the scanning process if DEBUG=true
    if (DEBUG)
        subplot(2,2,1);
        imagesc(sequence_function(i));
        title('Input (SLM)');
        
        subplot(2,2,2);
        imagesc(frame);
        title('Output (Camera)');
        
        subplot(2,2,3);
        imagesc(db(myfft2(frame)));
        title('FFT(Output)');
        
        subplot(2,2,4);
        imagesc(abs(myifft2(sequence_function(i))));
        title('kx, ky');
        drawnow;
    end

    % Progress meter
    progress(i,number_of_frames);
end
  
% Reconfigure camera
stop(vid);
set(vid.source, 'ExposureMode', 'TriggerWidth');

% Background subtraction
data_rec = bsxfun(@minus,data_rec,background_vector);

% Check reconstuction
figure;
subplot(1,2,1);
imagesc(abs(output_to_field(data_rec(:,1))));
subplot(1,2,2);
imagesc(db(fftshift(fft2(output_to_field(data_rec(:,1))))));
title('Reconstruction');
pause(0.010);


%% Corrections
% Drift compensation
[T, time_matrix, ...
 corr_cal, power_cal, pred_cal, time_cal, ...
 data_rec_cal_mean, data_rec_cal_std ] ...
       = drift_correction(data_rec, time, calibration_frames);
clear data_rec;
   
% Energy normalization
disp('Energy normalization...');
normalization_factor = sqrt(sum(abs(data_rec_cal_mean(:)).^2));
T = T./normalization_factor;

%% Alignment checks
disp('Calculating fiber transmission...');
fiber_trans_prox = unmask(sqrt(mean(real(T).^2 + imag(T).^2,1)), slm_params.freq.mask1);
img_trans_prox = ind2rgb(round(1+255*rescale(fiber_trans_prox,[0.0001 1.00])),gray(256));
figure; subplot(1,2,1);
image(unmask(mask(img_trans_prox, slm_params.freq.mask1), clip_mask(slm_params.freq.mask1)));
axis image; box off;
title('Proximal side transmission');

fiber_trans_dist = unmask(sqrt(mean(real(T').^2 + imag(T').^2,1)), holo_params.freq.mask1);
img_trans_dist = ind2rgb(round(1+255*rescale(fiber_trans_dist,[0.0001 1.00])),gray(256));
subplot(1,2,2);
image(unmask(mask(img_trans_dist, holo_params.freq.mask1), clip_mask(holo_params.freq.mask1)));
axis image; box off;
title('Distal side transmission');

%% Inversion of the transmssion matrix
disp('Inversion...');
% script_tm8_inversion_svd;
inversions = struct();
inversions.T_inv = T';
inversions.InversionMethod = 'T''';


%% Validation
% Choice of patterns
disp('Generating test patterns...');      
script_tm8_patterns_short;

% Define alternative input functions
mask_input_gs = imdilate(mask_input,strel('disk',5));
% mask_input_gs = mask_input;
input_to_slm_gs = @(v)phase_gs2(ifft2(ifftshift2(unmask(v,mask_input))),mask_input_gs,50);
% input_to_slm_mp = @(v)phase_mp(ifft2(ifftshift2(unmask(v,mask_input))));

% Generate test masks
disp('Generating inputs...');                               
experiments = patterns_generate(patterns,...
                                inversions, ...
                                T, ...
                                input_to_slm,...
                                slm_to_input,...
                                field_to_output);

% Measure response to test masks
disp('Recording response to test patterns...');
set(vid.source, 'ExposureMode', 'TriggerWidth');
h_fig = figure;
for i=1:numel(experiments)
    % Show on SLM
    slm.Write_img(experiments(i).SLM);
    
    % Pause
    pause(0.100);
    
    % Grab frame
    experiments(i).I_out = get_frame(vid, holo_params.exposure, false);

    % Show image
    figure(h_fig);
    imagesc(experiments(i).I_out);
    axis image; axis off;
    title({['Experiment #' num2str(i)], ...
           'Output'});
end
display('Writing constant phase mask to SLM...');
slm.Write_img(255.*ones(512, 512));


%% Finish
% Total time
toc(tic_global);
total_time = toc(tic_global);


%% Save data
% Timestamp
stamp = clock;
stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];

display('Saving data for later use...');
% Ask for name of file
% str = input('Enter a description for this dataset (or CTRL-C to stop without saving):\n','s');
% if numel(str)==0
%     str = name_of_script;
% end
str = '_CW_experiment_100micron'
data_filename = ['./data/' stamp_str ' ' str '.mat'];
save2(data_filename,...
       '*',...
       '-bytes>100000000',...
       '-class:handle',...
       '-class:videoinput',...
       '-class:videosource',...
       '-class:gigeinput',...
       '-class:gigesource',...
	   '-inversions',...
       '-input_function',...
       '-input_matrix',...
       '-output_matrix',...
       '-data_rec',...
       '-U',...
       '-S',...
       '-V',...
       '-Tb',...
       '-X_spots',...
       '-Y_spots',...
       '-V_sensor',...
       '-phase_factor',...
       '-phase_factor_v',...
       '-spot_function',...
       '-stack_bg',...
       '-stack_hdr',...
       '-y',...
       'T',...
       'Archive',...
       'experiments',...
       '/list-skipped');

   
% 
% Anonymous function that wraps all the steps up to form a spot. It takes
% as an argument the 'x,y' coordinates of where to form the spot in the
% image.
% NOTE:
%  x=0, y=0 forms a spot in the middle of the image.  
spot_phase_mask = @(x,y) uint8(input_to_slm(inversions.T_inv * ...
                                            field_to_output(pattern_spot(fiber_mask, x, y))));

slm.Write_img(spot_phase_mask(0, 0));
   
   
%% Form the scan.
% display('Computing the scan sequence for the SLM...');
% fiber_mask = holo_params.fiber.mask2;
x_range = -30:10:30; 
y_range = -30:10:30; 

% Holds all of the SLM masks to form a range of spots. We want to pre-form
% these to speed up the SLM update speed. Otherwise we are only able to
% refresh the SLM as fast as we are able to calculate an FFT, reshape the
% result, perform the matrix multiplication, and then form the iFFT and
% reshape once again.
spots = struct();
spots.working_dist_100um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
spots.working_dist_200um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
spots.working_dist_300um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
spots.working_dist_400um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
spots.working_dist_500um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));

index = 0;

% Boolean controlling how the scan is formed. Either line-by-line or raster
% scanning.
LINE_SCAN = false;
RASTER_SCAN = ~LINE_SCAN; % We can only do one or the other type of scan.
if (RASTER_SCAN)
    display('(Raster scan)');
else
    display('(Line-by-line scan)');
end

% These values were found from a set of previous experiments and only make
% sense to use with the imaging system in place to image the focus onto the
% camera at different distances. If anything changes these values are
% nonsensical. 
magnification_at_200um = 21.5;
distance_200um = 4*25.4e-6;
magnification_at_300um = 19.65;
distance_300um = 8*25.4e-6;
magnification_at_400um = 18.3;
distance_400um = 12*25.4e-6;
magnification_at_500um = 17.25;
distance_500um = 16*25.4e-6;

% Needed for propagation.
camera_pixel_pitch = 8e-6;
lambda = 785e-9;

progress(0, length(x_range)*length(y_range));
for i = x_range
    
    if (RASTER_SCAN)
        y_range = -1*y_range;
    end
    
    for j = y_range
        index = index + 1;
        
        % This must match the frame size used to form the transmission
        % matrix, otherwise the masking and indexing will fail below.
        output_to_propagate = zeros(camera_width_pixels, camera_height_pixels);
        % Form a 'focus spot' as an output.
        output_to_propagate(round(camera_width_pixels/2)+i,...
                            round(camera_width_pixels/2)+j) = 1; 
        
        % Initialize fields array.
        fields = [];
        

        % If trained at a location (e.g. 100 um) then we don't need to
        % propagate.
        % FIXME:
        % - Why must 'i', and 'j' be swapped to match the indexing in
        % 'output_to_propagate'. Otherwise the spot is scanned differently.
        field_100um = pattern_spot(fiber_mask,j,i);
        
        % Otherwise we need to propagate for each distance.
        [field_200um] = propagate_v2(output_to_propagate, ...
                                     distance_200um, ... 
                                     camera_pixel_pitch, ...
                                     lambda, ...
                                     magnification_at_200um);
        [field_300um] = propagate_v2(output_to_propagate, ...
                                     distance_300um, ... 
                                     camera_pixel_pitch, ...
                                     lambda, ...
                                     magnification_at_300um);
        [field_400um] = propagate_v2(output_to_propagate, ...
                                     distance_400um, ... 
                                     camera_pixel_pitch, ...
                                     lambda, ...
                                     magnification_at_400um);
        [field_500um] = propagate_v2(output_to_propagate, ...
                                     distance_500um, ... 
                                     camera_pixel_pitch, ...
                                     lambda, ...
                                     magnification_at_500um);                         
        
        
        % Assign all the fields to be converted for each spot location and
        % depth.
        fields(:,:,1) = field_100um;
        fields(:,:,2) = field_200um;
        fields(:,:,3) = field_300um;
        fields(:,:,4) = field_400um;
        fields(:,:,5) = field_500um;
               
        
        % Walk through the transmission matrix backwards to get the mask
        % needed for the SLM to form the output we wanted.
        Y_targets = field_to_output(fields);
        X_invs = inversions.T_inv * Y_targets;
        SLM_propagated_masks = uint8(input_to_slm(X_invs));
        
        % Assign each mask for each spot to the given depth for later use.
        spots.working_dist_100um(:,:,index) = SLM_propagated_masks(:,:,1);
        spots.working_dist_200um(:,:,index) = SLM_propagated_masks(:,:,2);
        spots.working_dist_300um(:,:,index) = SLM_propagated_masks(:,:,3);
        spots.working_dist_400um(:,:,index) = SLM_propagated_masks(:,:,4);
        spots.working_dist_500um(:,:,index) = SLM_propagated_masks(:,:,5);
        
        
        
%         % Save desired target vector
%         % i = 0; j = 0;
%         % i = -36; j = 35;
%         % i = 123; j = -35;
%         Y_target = field_to_output(pattern_spot(fiber_mask,j,i));
% 
%         % Calculate corresponding input pattern
%         X_inv = inversions.T_inv * Y_target;
%         
%         % Calculate the required SLM mask
%         %SLM_mask = input_to_slm(conj(X_inv));
%         SLM_mask = uint8(input_to_slm(X_inv));
%         
%         spots(:,:,index) = SLM_mask;
%         
%         % Write to the SLM.
%         slm.Write_img(SLM_mask);
        
        
%        % From the SLM mask, get the experimental input that is actually sent to the fiber
%        % (there may be distortions due to the use of a phase-only mask)
%        experiments(i,j).X_inv_exp   = slm_to_input(experiments(i,j).SLM);
%
%        % Simulate the output, both for the theoretical input and the
%        % experimental input
%        experiments(i,j).Y_sim       = T * experiments(i,j).X_inv;
%        experiments(i,j).Y_sim_exp   = T * experiments(i,j).X_inv_exp;
        
    end
    progress(index, length(x_range)*length(y_range));
end

% display('Adding spot formation data to .mat file');
% save(data_filename, 'spots','-append');




%% Scan the spots in an infinite loop!
% while 1
%     for i = 1:size(spots.working_dist_100um, 3)
%         slm.Write_img(spots.working_dist_100um(:,:,i));
%         pause(0.125);
%         slm.Write_img(spots.working_dist_200um(:,:,i));
%         pause(0.125);
%         slm.Write_img(spots.working_dist_300um(:,:,i));
%         pause(0.125);
%         slm.Write_img(spots.working_dist_400um(:,:,i));
%         pause(0.125);
%         slm.Write_img(spots.working_dist_500um(:,:,i));
%         pause(0.125);
%     end
% end





%% Scan a single spot using the memory effect.
% %% NOTE: Only valid with the multicore fibers, otherwise information is scrambled.
% while 1
% for i = -10:2:10
%     grating = zeros(512,512);
%     grating(256+i,256) = 1;
%     carrier_phase = myifft2(grating);
%     carrier_phase = radians_to_8bit_phase(carrier_phase);
%     slm.Write_img(uint8(spots(:,:,10)) + carrier_phase);
%     pause(0.15);
% end
% end

break


%% Propagate the spot a given distance.
% NOTE:
% - The camera frame must match the size used to form the transmission
% matrix. If there is an error about masks not matching frame sizes, this
% is likely the reason. Force a reset to original dimensions here just in
% case it was changed.
vid.ROIPosition = [camera_frame_offsetX_pixels camera_frame_offsetY_pixels...
                   camera_width_pixels camera_height_pixels];
               
% Function accepts the output that you would like to propagate. For example,
% to propagate a spot, send in a matrix (match camera frame dimensions used
% to form the transmission matrix) with a single pixel set to 1.
output_to_propagate = zeros(camera_width_pixels, camera_height_pixels);
output_to_propagate(round(camera_width_pixels/2),...
                    round(camera_height_pixels/2)) = 1;

                
                
distance_100um = 4*25.4e-6;                
                
%magnification_at_200um = 21.5;
distance_200um = 8*25.4e-6;

%magnification_at_300um = 19.65;
distance_300um = 12*25.4e-6;

%magnification_at_400um = 18.3;
distance_400um = 16*25.4e-6;

%magnification_at_500um = 17.25;
distance_500um = 20*25.4e-6;

magnifications = [15:0.15:26];
%distances = [1:1:6].*25.4e-6;

distances = distance_300um

camera_pixel_pitch = 8e-6;
lambda = 785e-9;
[fields] = propagate_v2(output_to_propagate, ...
                        distances, ... 
                        camera_pixel_pitch, ...
                        lambda, ...
                        magnifications);
Y_targets = field_to_output(fields);
X_invs = inversions.T_inv * Y_targets;
SLM_propagated_masks = uint8(input_to_slm(X_invs));

% Find the correct magnification to use at this propagation distance using
% the imaging system we have in place with the camera.
peak_focus_intensity = [];
for i=1:size(SLM_propagated_masks, 3)
    slm.Write_img(SLM_propagated_masks(:,:,i));
    peak_focus_intensity = [peak_focus_intensity, max(max(get_frame(vid, 50, false)))];
    pause(0.05);
end
% Plot the result of using each magnification at this propagation distance.
figure, plot(magnifications, peak_focus_intensity);
% Find the index that produced the peak intensity in the focus.
peak_index = find(peak_focus_intensity == max(peak_focus_intensity));
fprintf('Magnification that produces the peak intensity in the focus is m=%d\n',...
         magnifications(peak_index));
     
% Propagate the      
display('Propagating beam using found magnification');
slm.Write_img(SLM_propagated_masks(:, :, peak_index));




%% Align the delay line (i.e. reference arm) using the Fourier domain as feedback.
% % stop(vid);
% % set(vid.source, 'ExposureMode', 'TriggerWidth');
% % start(vid);
% % figure;
% % while 1
% % %     frame = get_frame(vid, 2000, false);
% % %     imagesc(db(fftshift2(fft2(frame))));
% % 
% %     trigger_camera(holo_params.exposure, [], 1, false);
% %     [frame, ~] = getdata(vid,1);
% %     imagesc(db(fftshift2(fft2(frame))));
% %     %imagesc(frame);
% %     drawnow;
% %     
% %    % pause(0.25);
% % end