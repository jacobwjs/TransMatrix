% Script to test the gigesource class
%   - Damien Loterie (11/2014)

% Create object
disp('Creating source...');
clear source vid;
source = gigesource('192.168.10.2');

% Configure
disp('Configuring...');
set(source,'TriggerMode','On');
set(source,'TriggerSource','Line1');
set(source,'ExposureMode','TriggerWidth'); 

% Configure
disp('Starting...');
start(source);

% Trigger
disp('Trigger...');
addpath('../../../tm11b');
n_frames = 10;
triggere('proximal', 1000, 5, n_frames);

% % Flush test
% disp('Flushing...');
% disp(['Frames: ' int2str(getnumberofimages(source))]);
% source.flush();
% 
% disp('Trigger...');
% triggere('proximal', 1000, 5, n_frames);

% Wait for frame
disp('Waiting for frame...');
n_frames = 10;
source.wait(n_frames, 5);
disp(['Frames: ' int2str(getnumberofimages(source))]);

% Stop
disp('Stopping...');
stop(source);

% Image
disp('Getting image(s)');
% frame = getlastimage(source);
[frames, time] = getimages(source, n_frames);
disp(['Frames gathered: ' int2str(size(frames,4))]);
disp(['Frames left: ' int2str(getnumberofimages(source))]);

% Errors
errors = source.geterrors();
disp(['Errors: ' int2str(numel(errors))]);

% Delete
disp('Delete...');
delete(source);
clear source;
