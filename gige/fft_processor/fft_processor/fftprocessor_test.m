% Demo script to test the FFTProcessor class
%  - Damien Loterie (03/2015)

% Includes
addpath('../../../tm9');
addpath('../../gige_interface/gige_interface');

% Create camera
disp('Creating source...');
clear source vid fftp dw;
vid = gigeinput('192.168.10.2');
source = vid.source;
vid.ROIPosition = [256 139 800 800];

% Create disk writer
disp('Creating fft processor...');
ind = mask_to_indices(true(800,800),'fftshifted-to-fftw-r2c-transpose');
fftp = fftprocessor(800,800,vid,ind);

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
triggere('proximal', 1000, 5, n_frames);

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

% % Delete
disp('Delete...');
delete(source);
delete(fftp);
clear vid source fftp;
