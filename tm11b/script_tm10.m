% Script to measure a transmission matrix.
% v8:  vsync-triggering is now handled by the DAQ card
% v8c: replaced camera interface with custom C++ code
% v9:  real-time disk writing and Fourier transform
% v10: SLM in configuration without beamsplitter (for correlation)
% - Damien Loterie (08/2015)

%% Initialize
% Cleanup
reset_all;

DEBUG = false;

% Shortcut functions
myfft2  = @(x) fftshift(fft2(ifftshift(x)));
myifft2 = @(x) fftshift(ifft2(ifftshift(x))); 
radians_to_8bit = @(img)uint8(mod(angle(img)*256/(2*pi), 256));

% Identify script
name_of_script = mfilename;

%% Initialize the hardware (SLM + Camera)
% -------------------------------------------------------------------------
% Initialize the SLM
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);

% Initialize camera
vid = camera_mex('distal', 'ElectronicTrigger');
% Define the ROI in the camera
camera_frame_offsetX_pixels = 352;
camera_frame_offsetY_pixels = 155;
camera_width_pixels   = 544;
camera_height_pixels  = 544;
vid.ROIPosition = [camera_frame_offsetX_pixels camera_frame_offsetY_pixels...
                   camera_width_pixels camera_height_pixels];
camera_exposure_us = 2000;



%% Calibration (configure fullscreen, camera and holography)
% -------------------------------------------------------------------------
% Define proximal-side calibration data
x_slm = slm.x_pixels;
y_slm = slm.y_pixels;
slm_params = struct();
slm_params.ROI = [0 0 x_slm y_slm];
slm_params.exposure = [];
% Assume the image of the fiber facet on the SLM is centered.
slm_params.fiber.x = 257;
slm_params.fiber.y = 257;

% DC in k-space (assuming a 512x512 grid)
% x_offset = 256;
% y_offset = 256;
% freq_x = -101;
% freq_y = 101;
slm_params.freq.x = 146; % x_offset + freq_x = 155;
slm_params.freq.y = 377; % y_offset + freq_y = 357;
slm_params.freq.r1 = 60;
slm_params.freq.r2 = slm_params.freq.r1;
slm_params = recalculate_square_masks(slm_params);
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
holo_params.freq.x = 456;   
holo_params.freq.y = 407;   

% The radius of the selected order in pixel count [k-space].
holo_params.freq.r1 = 30;  
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

%% Pre-measurement checks
% Check order
figure;
calibration_frame2 = uint8(mod(double(calibration_frame)+64,256));
slm.Write_img(calibration_frame);
frame1 = get_frame(vid, holo_params.exposure, false);

slm.Write_img(calibration_frame2);
frame2 = get_frame(vid, holo_params.exposure, false);

imagesc(angle(fft2(frame2).*conj(fft2(frame1))));
title('Order verification');  

% Check distal mask
figure;
imagesc(db(double(fftshift2(fft2(frame1))).*holo_params.freq.mask1));
title('Mask verification');

figure;
imagesc(db(double(fftshift2(fft2(frame1))).*~holo_params.freq.mask1));
title('Mask verification');

% Confirmation
disp('Press a key to continue...');
pause;

%% Measurement
% Background correction
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


%% Finish
% Total time
toc(tic_global);
total_time = toc(tic_global);

% Timestamp
stamp = clock;
stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];

%% Save data
% Ask for name of file
% str = input('Enter a description for this dataset (or CTRL-C to stop without saving):\n','s');
% if numel(str)==0
%     str = name_of_script;
% end
% str = '_CW_experiment';
% save2(['./data/' stamp_str ' ' str '.mat'],...
%        '*',...
%        '-bytes>100000000',...
%        '-class:handle',...
%        '-class:videoinput',...
%        '-class:videosource',...
%        '-class:gigeinput',...
%        '-class:gigesource',...
% 	   '-inversions',...
%        '-input_function',...
%        '-input_matrix',...
%        '-output_matrix',...
%        '-data_rec',...
%        '-U',...
%        '-S',...
%        '-V',...
%        '-Tb',...
%        '-X_spots',...
%        '-Y_spots',...
%        '-V_sensor',...
%        '-phase_factor',...
%        '-phase_factor_v',...
%        '-spot_function',...
%        '-stack_bg',...
%        '-stack_hdr',...
%        '-y',...
%        'T',...
%        'Archive',...
%        'experiments',...
%        '/list-skipped');

% Scan the spot.
fiber_mask = holo_params.fiber.mask2;
x_range = -200:5:200; %-40:1:40;
y_range = -200:5:200; %-40:1:40;
for i = x_range
    for j = y_range
        % Save desired target vector
        %i = 0; j = 2;
        %i = -36; j = 35;
        %i = 123; j = -35;
        Y_target = field_to_output(pattern_spot(fiber_mask,j,i));

        % Calculate corresponding input pattern
        X_inv = inversions.T_inv * Y_target;
        
        % Calculate the required SLM mask
        SLM_mask = input_to_slm(conj(X_inv));
        
        % Write to the SLM.
        slm.Write_img(SLM_mask);
        
        %        % From the SLM mask, get the experimental input that is actually sent to the fiber
        %        % (there may be distortions due to the use of a phase-only mask)
        %        experiments(i,j).X_inv_exp   = slm_to_input(experiments(i,j).SLM);
        %
        %        % Simulate the output, both for the theoretical input and the
        %        % experimental input
        %        experiments(i,j).Y_sim       = T * experiments(i,j).X_inv;
        %        experiments(i,j).Y_sim_exp   = T * experiments(i,j).X_inv_exp;
        
    end
end

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