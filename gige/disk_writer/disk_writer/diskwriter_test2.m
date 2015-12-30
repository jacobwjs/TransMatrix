% Script to test the diskwriter class.
%   - Damien Loterie (03/2015)

% Includes
addpath('../../../tm11b');
addpath('../../../dx11tut11_mod3/Engine/MATLAB');
addpath('../../gige_interface/gige_interface');

% Create dx_fullscreen
if ~exist('d','var')
   d = dx_fullscreen; 
end

% Create camera
disp('Creating source...');
clear source vid dw;
vid = camera_mex('distal','ElectronicTrigger');
vid.ROIPosition = [256 139 800 800];

% Create disk writer
disp('Creating disk writer...');
clear dw;
dw = diskwriter('C:\video.dat', vid, false);

% Configure
disp('Measuring...');
number_of_frames = round(11769); % 11769
exposure = 2500;
x_img = d.getConfig('frameWidth');
y_img = d.getConfig('frameHeight');
sequence_function = @(n)zeros([x_img,y_img,numel(n)],'uint8');
measurement_stats = measure_sequence(d, ...
                                     dw, ...
                                     exposure, ...
                                     sequence_function, ...
                                     number_of_frames);
                                 
% Memory
plot(measurement_stats.memory.Time, ...
     100*(1-measurement_stats.memory.PhysicalMemoryAvailable/measurement_stats.memory.PhysicalMemoryTotal));
xlabel('Time [s]');
ylabel('Memory usage');
v = axis; v(3:4) = [0 100]; axis(v);

% Errors
errors = vid.source.geterrors();
disp(['Errors: ' int2str(numel(errors))]);

% % Delete
% disp('Delete...');
% delete(dw);
% delete(vid);
% clear source dw vid;
