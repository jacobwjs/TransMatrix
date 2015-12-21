% Demo script to test the FFTProcessor class
%  - Damien Loterie (03/2015)

% Includes
addpath('../../../tm9');
addpath('../../../dx11tut11_mod3/Engine/MATLAB');
addpath('../../gige_interface/gige_interface');
addpath('../../disk_writer/disk_writer');

% Create dx_fullscreen
if ~exist('d','var')
   d = dx_fullscreen; 
end

% Create camera
disp('Creating source...');
clear source vid dw fftp;
vid = camera_mex('distal','ElectronicTrigger');
vid.ROIPosition = [256 139 800 800];
source = vid.source;

% Create disk writer
disp('Creating disk writer...');
dw = diskwriter('C:\video.transposed.dat', vid, true);

% Create disk writer
disp('Creating FFT procesor...');
ind = mask_to_indices(mask_circular([800, 800],[],[],50),'fftshifted-to-fftw-r2c-transpose');
% ind = mask_to_indices(true(800,800),'fftshifted-to-fftw-r2c-transpose');
fftp = fftprocessor(800,800,dw,ind);

% Configure
disp('Measuring...');
number_of_frames = round(100);
exposure = 2500;
x_img = d.getConfig('frameWidth');
y_img = d.getConfig('frameHeight');
sequence_function = @(n)zeros([x_img,y_img,numel(n)],'uint8');
measurement_stats = measure_sequence(d, ...
                                     fftp, ...
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
fftp_errors   = fftp.geterrors();
dw_errors     = dw.geterrors();
source_errors = source.geterrors();
disp(['Errors (source): ' int2str(numel(source_errors))]);
disp(['Errors (dw):     ' int2str(numel(dw_errors))]);
disp(['Errors (fftp):   ' int2str(numel(fftp_errors))]);

% Data
disp('Getting image(s)');
data = getdata(fftp,get(fftp,'FramesAvailable'));
disp(['Frames expected:    ' int2str(number_of_frames)]);
disp(['Frames fftp:        ' int2str(size(data,2))]);
disp(['Frames left in dw:  ' int2str(get(dw,'FramesAvailable'))]);
disp(['Frames left in vid: ' int2str(get(vid,'FramesAvailable'))]);


% Delete
disp('Delete...');
delete(fftp);
delete(dw);
delete(vid);
delete(source);
clear source dw vid fftp;
