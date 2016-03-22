% Demo script to test the FFTProcessor class
%  - Damien Loterie (03/2015)

% Includes
% addpath('../../../tm11b');
% addpath('../../gige_interface/gige_interface');

reset_all;

% Create camera
disp('Creating source...');
%vid = gigeinput('192.168.10.2');
vid = camera_mex('distal','ElectronicTrigger');

dim_x = 576;
dim_y = 576;

source = vid.source;
vid.ROIPosition = [320 288 dim_x dim_y];

% Create disk writer
disp('Creating fft processor...');
ind = mask_to_indices(true(50, 50), 'fftshifted-to-fftw-r2c-transpose');
fftp = fftprocessor(dim_x, dim_y, vid, ind);

% Configure
disp('Configuring...');
set(source,'TriggerMode','On');
set(source,'TriggerSource','Line1');
set(source,'ExposureMode','TriggerWidth'); 

% Configure
disp('Starting...');
start(vid);

% Trigger
disp('Trigger...');

n_frames = 10;
%triggere('proximal', 1000, 5, n_frames);
%trigger_camera(1e3, 5, n_frames, false);
for i=1:n_frames
    trigger_camera(1e3, [], 1, false);
    pause(0.025);
end

% Stop
disp('Stopping...');
stop(source);

% Images
disp('Getting image(s)');
data = getdata(fftp,n_frames);
disp(['Frames gathered: ' int2str(size(data,2))]);
disp(['Frames left: ' int2str(get(fftp,'FramesAvailable'))]);
disp(['Frames left in source: ' int2str(get(vid,'FramesAvailable'))]);

% Errors
fftp_errors = fftp.geterrors();
source_errors = source.geterrors();
disp(['Errors (fftp):    ' int2str(numel(fftp_errors))]);
disp(['Errors (sources): ' int2str(numel(source_errors))]);


