% Script to measure a transmission matrix.
% - Damien Loterie (08/2015)
%
% Moving the design and overall structure as a template to implement TM
% measurements with the Meadowlark Overdrive Plus SLM.
% - Jacob Staley (01/2016)

%% Initialize
% Cleanup
reset_all;

% Identify script
name_of_script = mfilename;

% Initialize the Meadowlark SLM.
% ---------------------------------------------------------------
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);
pause(0.25);
% Put previously calculated blazed grating on the SLM that couples light
% into the fiber.
blazed_grating = zeros(512, 512);
blazed_grating(256+141,256) = 1;
blazed_grating = angle(fftshift(fft2(ifftshift(blazed_grating))));
% Convert the phase map to 256 (8-bit) discrete values that the SLM uses to
% map voltages to phase for the given calibration.
blazed_grating = uint8(mod(blazed_grating*256/(2*pi), 256));
% Update the SLM.
slm.Write_img(blazed_grating);

% FIXME:
%  - This does not work based on the values returned by 'slm_getcal_v2()'.
%    Why? This means the changes I've made to 'slm_getcal_v2()' for the
%    meadowlark SLM are potentially wrong.
% calibration_frame = modulation_slm(slm_params.ROI(3), ...
%                                    slm_params.ROI(4), ...
%                                    slm_params.freq.x, ... % + slm_params.freq.r1/2
%                                    slm_params.freq.y);

% Initialize the camera
% ---------------------------------------------------------------
vid = camera_mex('distal','ElectronicTrigger');

% % Configure the camera for holography
% ----------------------------------------------------------------
% holo_params = holography_calibration(vid);
% % load('holography_cal_data.mat'); holo_params = params(strcmp({params.DeviceName},'distal')); clear params;
% % holo_params.exposure = auto_exposure(vid);
camera_exposure_us = 2e3;
holo_params = holography_calibration_v2(vid, camera_exposure_us); 

disp(['Output mask: ' int2str(sum(holo_params.freq.mask1(:))) ' pixels (r=' int2str(holo_params.freq.r1) ')']);
disp(['Output ROI:  ' int2str(holo_params.ROI(3)) 'x' int2str(holo_params.ROI(4))]);
disp(['Exposure:    ' num2str(round(holo_params.exposure)) 'us']);

% Check the grid size in order to maximize the fft speed.
fft_size_check(holo_params.ROI(3));
if (holo_params.ROI(3) ~= holo_params.ROI(4))
    fft_size_check(holo_params.ROI(4));
end

% Check exposure
if holo_params.exposure<1000
   str = input('The exposure is too low. Do you want to continue? ','s');
    if ~strcmpi(str,'y')
       error('Aborted.')
    end
end


% % Get the calibration parameters of the SLM.
% ----------------------------------------------------------------
slm_params = slm_getcal_v2(slm.props, holo_params);

% FIXME:
%  - This does not work based on the values returned by 'slm_getcal_v2()'.
%    Why? This means the changes I've made to 'slm_getcal_v2()' for the
%    meadowlark SLM are potentially wrong.
calibration_frame = blazed_grating;
calibration_frame = modulation_slm(slm_params.ROI(3), ...
                                   slm_params.ROI(4), ...
                                   slm_params.freq.x, ... % + slm_params.freq.r1/2
                                   slm_params.freq.y);

% Check grid size
fft_size_check(slm_params.ROI(3));
if slm_params.ROI(3)~=slm_params.ROI(4)
    fft_size_check(slm_params.ROI(4));
end

% Output
disp(['Input mask:  ' int2str(sum(slm_params.freq.mask1(:))) ...
      ' pixels (r=' int2str(slm_params.freq.r1) ')']);
disp(['Input ROI:   ' int2str(slm_params.ROI(3)) ...
      'x' int2str(slm_params.ROI(4))]);




% Timing
tic_global = tic;

%% Definitions
% [INPUT BASIS]
% [RECONSTRUCTION]
% [OUTPUT BASIS]
script_tm10_basis;


% Basis size info
disp(['Basis size:  '...
      num2str(sum(sum(holo_params.freq.mask1)))...
      ' pixels by ' num2str(input_size(2)) ' frames']);





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
                                                                                    
%% Measurement
% Check order
disp('Verifying holographic order that was selected.');
order_check = measure_order_v2(slm, vid, holo_params.exposure,...
                               calibration_frame, camera_to_field);
if ~order_check
    error('The wrong holographic order has been selected.');
else
    display('Correct order selected');
end
                                          
% warning('Skipping background correction...');
% Take a picture of the reference wave and background, for control.
% ------------------------------------------ JWJS ------------------------
disp('Begin recording reference wave and background:');
[reference_mean, reference_std, background_mean, background_std] = ...
           measure_reference(vid, holo_params.exposure);


%% Initialize the disk writer
% ---------------------------------------------------------------
% addpath('../gige/disk_writer/disk_writer/');
% dump_path = 'C:\Users\admin\Desktop\Jacob\TransMatrix\tm11b\data\trans.video.dat';
% fprintf('Writing to %s\n', dump_path);
% dw = diskwriter(dump_path, vid, true);


%% Initialize the FFT processor
% ---------------------------------------------------------------
% addpath('../gige/fft_processor/fft_processor/');
% fftp_ind = mask_to_indices(holo_params.freq.mask1, 'fftshifted-to-fftw-r2c-transpose');
% %fftp = fftprocessor(holo_params.ROI(3), holo_params.ROI(4), dw, fftp_ind);
% fftp = fftprocessor(holo_params.ROI(3), holo_params.ROI(4), vid, fftp_ind);

                                          
% Measurement
[frames, measurement_stats] = measure_sequence_v2(slm, ...
                                                    vid, ...
                                                    holo_params.exposure, ...
                                                    sequence_function, ...
                                                    number_of_frames, ...
                                                    holo_params.freq.mask1);                                           
                                           







%
% % Test for the misplaced shutter error
% % if mean(abs(camera_to_output(reference_mean)).^2)>100
% %    error('Possible malfunction in the proximal shutter. Background correction will fail.');
% % end
%

% % Get data
% [data_rec, time] = getdata(fftp, number_of_frames);
% % getdata_workaround;
%
% % Background subtraction
data_rec = bsxfun(@minus,frames,mask(fftshift2(fft2(reference_mean)),holo_params.freq.mask1));
%
% % Delete extra objects
% delete(fftp);
% delete(dw);
% clear fftp dw;
%
% % Check reconstuction
figure;
subplot(1,2,1);
imagesc(abs(output_to_field(data_rec(:,1))));
subplot(1,2,2);
imagesc(db(fftshift(fft2(output_to_field(data_rec(:,1))))));
title('Reconstruction');
pause(0.010);
%
%
% %% Archival and reorganization
% % Save some data for later reference
% disp('Archival...');
% number_of_frames_rec = size(data_rec,2);
% FramesToArchive = [1:20 randi(number_of_frames_rec,1,20) (number_of_frames_rec-19):number_of_frames_rec];
% FramesToArchive = unique(FramesToArchive(FramesToArchive>0 & FramesToArchive<=number_of_frames_rec));
% Archive = struct();
% Archive.data_rec = data_rec(:,FramesToArchive);
% Archive.data_in  = sequence_function(FramesToArchive);
% Archive.time     = time(FramesToArchive);
% Archive.Indices  = FramesToArchive;
% Archive.data_out = video_read(dump_path, 'uint16', [holo_params.ROI(4) holo_params.ROI(3)], FramesToArchive);
% Archive.data_out = permute(Archive.data_out,[2 1 3]);
%
% % Function to read frames from the dump for verification
% video_stack = @(n)permute(video_read(dump_path, 'uint16', [holo_params.ROI(4) holo_params.ROI(3)], n),[2 1 3]);
%
%% Corrections
% Drift compensation
% [output_matrix, time_matrix, ...
%  corr_cal, power_cal, pred_cal, time_cal, ...
%  data_rec_cal_mean, data_rec_cal_std ] ...
%        = drift_correction(data_rec, time, calibration_frames);
% clear data_rec;  
[output_matrix, time_matrix, ...
 corr_cal, power_cal, pred_cal, time_cal, ...
 data_rec_cal_mean, data_rec_cal_std ] ...
       = drift_correction(data_rec, ...
                          measurement_stats.Frame_acq_time, ...
                          calibration_frames);

  


% % Energy normalization
disp('Energy normalization...');
normalization_factor = sqrt(sum(abs(data_rec_cal_mean(:)).^2));
output_matrix = output_matrix./normalization_factor;



%% Transmission matrix
disp('Transmission matrix...');

% Create input matrix if it does not already exist
if ~exist('input_matrix','var')
    input_matrix = input_function(1:input_size(2));
end

% Create the transmission matrix
if input_unitary
    T = output_matrix * input_matrix';
else
    tic_ls = tic;
    disp('(using least-squares)');
    %T = lscov(input_matrix.', output_matrix.').';
    T = double(output_matrix)/double(input_matrix);
    time_ls = toc(tic_ls); toc(tic_ls);
end
clear output_matrix;
clear input_matrix;

 


% % Save TM in full precision
stamp = clock;
stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];
save2(['./data/' stamp_str ' tm10 (matrix full precision).mat'],'T','-v7.3');

% % % Convert to single
% % warning('Converting matrix to single precision...');
% % T = single(T);
%
% %% Alignment checks
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
script_tm8_inversion_svd;


% %% Bottle beam display
% % mask_input_gs = imdilate(mask_input,strel('disk',5));
% % input_to_slm_gs = @(v)phase_gs2(ifft2(ifftshift2(unmask(v,mask_input))),mask_input_gs,50);
% % disp('Waiting for generation.');
% % test_bottle_generate2;
% % test_bottle_display2;
% % % disp('Waiting for alignment.');
% % % pause;
%

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
                                input_to_slm_gs,...
                                slm_to_input,...
                                field_to_output);

% Measure response to test masks
disp('Recording response to test patterns...');
[experiments, speckle_ref] = patterns_measure_v2(vid, ...
                                              slm, ...
                                              camera_to_output, ...
                                              camera_to_field, ...
                                              experiments, ...
                                              calibration_frame, ...
                                              camera_exposure_us);

% Analyze results
disp('Analyzing results...');
disp(' ');
experiments = patterns_analyze(experiments, ...
                               speckle_ref, ...
                               holo_params.fiber.mask1);

%% Finish
% Total time
toc(tic_global);
total_time = toc(tic_global);

% Timestamp
stamp = clock;
stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];

% Plot window
patterns_plot(experiments, holo_params, slm_params, stamp_str);

% %% Save data
% % Ask for name of file
% str = input('Enter a description for this dataset (or CTRL-C to stop without saving):\n','s');
% if numel(str)==0
%     str = name_of_script;
% end
%
%
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




