% Script to find the right fiber positions on the SLM
% - Damien Loterie (07/2014)

%% Initialize
% Cleanup
reset_all

% Identify script
name_of_script = mfilename;

% No reference needed
shutter('distal','block');

%% Configure fullscreen, camera and holography
% Fullscreen parameters
[x_slm, y_slm] = slm_size();

% Open fullscreen window
addpath(dx_fullscreen_path);
dx_options = struct('monitor',      1,...
                    'screenWidth',  x_slm,...
                    'screenHeight', y_slm,...
                    'frameWidth',   x_slm,...
                    'frameHeight',  y_slm,...
                    'renderWidth',  x_slm,...
                    'renderHeight', y_slm,...
                    'renderPosX',   0,...
                    'renderPosY',   0);
d = dx_fullscreen(dx_options);

% Get the previous estimate of the fiber position in the Fourier domain
slm_params = slm_getcal('ROIPosition',[0,0],...
                        'ROISize',[x_slm y_slm]);

% Prepare sweep parameters
stripe_size = 101;
sweep_step = 5;
fiber_estimated_radius = 383;

% Create a calibration frame
calibration_frame = modulation_slm(x_slm, y_slm, slm_params.freq.x, slm_params.freq.y);
                                            
% Show the calibration frame
d.show(calibration_frame);
pause(0.5);
              
% Initialize camera
% vid = camera('distal','ElectronicTrigger');
if ~exist('vid','var')
    vid = camera_mex('distal');
end

% Configure the camera
exposure = auto_exposure3(vid,100,0.5,0.85,true);

% Adapt exposure in function of the size of the stripe
r = fiber_estimated_radius;
x0 = stripe_size/2;
fiber_area = pi*r^2;
stripe_area = 2 * (x0 * sqrt(r^2 - x0^2) + r^2 * asin(x0/r));
exposure = exposure*fiber_area/stripe_area;

disp(['Exposure: ' num2str(exposure) 'us']);

%% Measurement of fiber position in spatial domain
disp('Generating inputs...');

% Create images
x_min = (stripe_size-1)/2;
x_max = (x_slm-1)-x_min;
x_steps = unique([x_min:round(sweep_step):x_max x_max]);
x_mask = 0:(x_slm-1);

y_min = (stripe_size-1)/2;
y_max = (y_slm-1)-y_min;
y_steps = unique([y_min:round(sweep_step):y_max y_max]);
y_mask = 0:(y_slm-1);

stack_in = zeros([size(calibration_frame) numel(x_steps)+numel(y_steps)+2],'like',calibration_frame);
x_ind = 1+(1:numel(x_steps));
y_ind = 1+((numel(x_steps)+1):(numel(x_steps)+numel(y_steps)));
for i=1:numel(x_ind)
    x_low = x_steps(i) - (stripe_size-1)/2;
    x_up  = x_steps(i) + (stripe_size-1)/2;
    stack_in(:,:,x_ind(i)) = bsxfun(@times, calibration_frame, uint8((x_mask>=x_low & x_mask<=x_up).'));
end
for i=1:numel(y_steps)
    y_low = y_steps(i) - (stripe_size-1)/2;
    y_up  = y_steps(i) + (stripe_size-1)/2;
    stack_in(:,:,y_ind(i)) = bsxfun(@times, calibration_frame, uint8(y_mask>=y_low & y_mask<=y_up));
end
sequence_function = @(n)stack_in(:,:,n);

%% Measurement
disp('Measurement...');
measurement_stats = measure_sequence(d, ...
                                     vid, ...
                                     exposure, ...
                                     sequence_function, ...
                                     size(stack_in,3));
clear stack_in sequence_function;
[stack,time] = getdata(vid,get(vid,'FramesAvailable'));

% Reset shutter
shutter('distal','reset');

% Calculate mean and max intensity
bg     = stack(:,:,1,end);
Ibg    = mean(bg(:));
Imean  = squeeze(mean(mean(stack))) - Ibg;
Imax   = squeeze(max(max(bsxfun(@minus,stack,bg))));
Ix     = Imean(x_ind);
Iy     = Imean(y_ind);
Ix_max = Imax(x_ind);
Iy_max = Imax(y_ind);


%% Processing
sx = spaps(x_steps,Ix,1500);
sy = spaps(y_steps,Iy,1500);

% Draw x
hx = clf;
plot(x_steps,Ix);
hold on;
fnplt(sx,'r');
hold off;

% Draw y
hy = figure;
plot(y_steps,Iy);
hold on;
fnplt(sy,'r');
hold off;

% Calculate x position
sx_max = max(fnval(sx,mean(fnzeros(fnder(sx)),1)));
sx_bounds = mean(fnzeros(fncmb(sx,'-',1/10*sx_max)),1);
if numel(sx_bounds)~=2
   error('Unexpected result in midpoint calculation'); 
end
sx_mid = mean(sx_bounds);
dx = diff(sx_bounds);

% Calculate x position
sy_max = max(fnval(sy,mean(fnzeros(fnder(sy)),1)));
sy_bounds = mean(fnzeros(fncmb(sy,'-',1/10*sy_max)),1);
if numel(sy_bounds)~=2
   error('Unexpected result in midpoint calculation'); 
end
sy_mid = mean(sy_bounds);
dy = diff(sy_bounds);

% Draw center x
figure(hx);
hold on;
plot(sx_bounds(1)*[1,1], [0 sx_max],'k');
plot(sx_mid*[1,1], [0 sx_max],'k--');
plot(sx_bounds(2)*[1,1], [0 sx_max],'k');
hold off;

% Draw center y
figure(hy);
hold on;
plot(sy_bounds(1)*[1,1], [0 sy_max],'k');
plot(sy_mid*[1,1], [0 sy_max],'k--');
plot(sy_bounds(2)*[1,1], [0 sy_max],'k');
hold off;

%% Process results
diameter = round(mean([dx dy])/100)*100;
diameter = 960;
ROI_new = [round([sx_mid-diameter/2, sy_mid-diameter/2]), diameter, diameter];

params = slm_params;
params.ROI = ROI_new;
params.fiber.x = round(sx_mid-ROI_new(1));
params.fiber.y = round(sy_mid-ROI_new(2));
[params.freq.x, params.freq.y] = ROI_transform(slm_params.freq.x, ...
                                               slm_params.freq.y, ...
                                               slm_params.ROI, ...
                                               ROI_new, ...
                                               'fftshift');
params.freq.r1 = slm_params.freq.r1 * ROI_new(3) / slm_params.ROI(3);
params.freq.r2 = slm_params.freq.r2 * ROI_new(3) / slm_params.ROI(3);

disp(' ');
disp('Results');
disp('-------');
disp(['x_off: ' int2str(params.ROI(1)) ' (old: ' int2str(slm_params.ROI(1)) ')']);
disp(['y_off: ' int2str(params.ROI(2)) ' (old: ' int2str(slm_params.ROI(2)) ')']);
disp(['x:     ' int2str(params.ROI(3)) ' (old: ' int2str(slm_params.ROI(3)) ')']);
disp(['y:     ' int2str(params.ROI(4)) ' (old: ' int2str(slm_params.ROI(4)) ')']);

% Show on SLM
img_test = ROI_place(randi(255,params.ROI([4 3]),'uint8'),...
                     zeros(y_slm,x_slm,'uint8'),...
                     params.ROI);
d.show(img_test.');

% Save
str = input('Update the SLM calibration [y/n]? ','s');
if strcmpi(str,'y')
    slm_setcal(params);
    disp('The new SLM calibration was saved');
else
    disp('Aborted.')
end
