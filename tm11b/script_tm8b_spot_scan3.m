% Script to scan spots over a certain area in front of the fiber,
% and collect the resulting sensor signal
%  - Damien Loterie (08/2015)

%% Spot calculation
% Wavelength

% Position of the spots
% 
% distance = 90*1e-6;
% x_range = 401;
% y_range = 401;

distance = (20)*1e-6; % -10 0 10 20 30 40 50
x_range = center_of(holo_params.ROI(3)) + (-300:3.5:300);
y_range = center_of(holo_params.ROI(4)) + (-300:3.5:300);

% distance = [20:150]*1e-6;
% x_range = 401 + (-240:8:240);
% y_range = 401;

% distance = 103*1e-6;
% x_range = 401 + (-80:6:80);
% y_range = 401 + (-80:6:80);

% distance = 103*1e-6;
% x_range = 451 + (-10:0.25:10);
% y_range = 451 + (-10:0.25:10);

% Voltage range
% V_range = 1.0;
V_range = 2.0;
% V_range = 10.0;

% Check parameters
N_spots = numel(x_range)*numel(y_range)*numel(distance);
disp(['There are ' int2str(N_spots) ' spots. ']);
disp(['This will take ' num2str(round(10*N_spots/(20*60))/10) ' minutes.']);
disp(['Measurement range: ' num2str(V_range) 'V']);
disp('Press any key to start...');
pause

% Coordinate combinations
pos = combvec(y_range,x_range);
px = pos(2,:);
py = pos(1,:);
i_center = round(numel(px)/2);

% Linear iffshifted input mask
mask_lin_pos = mask_to_indices(holo_params.freq.mask1c, 'fftshifted-to-fft');

% Fourier domain grid of spots
Nx = size(holo_params.freq.mask1c,2);
Ny = size(holo_params.freq.mask1c,1);

[Xfd,Yfd] = meshgrid(fft_axis(Nx), ...
                     fft_axis(Ny));
                 
xfd = 2*pi*Xfd(mask_lin_pos)/Nx;
yfd = 2*pi*Yfd(mask_lin_pos)/Ny;

Y_spots = exp(-1i*(bsxfun(@times,px-1,xfd) + bsxfun(@times,py-1,yfd)));

% Propagation factors
distance_propagation = distance;

[~,phase_factor] = propagate(zeros(Ny,Nx),distance,'fiber');
phase_factor_v = mask_linear(phase_factor,mask_lin_pos);
phase_factor_v = reshape(phase_factor_v,[numel(mask_lin_pos) 1 numel(distance)]);

Y_spots = bsxfun(@times,Y_spots,phase_factor_v);
Y_spots = reshape(Y_spots,numel(mask_lin_pos),[]);

% Calculate corresponding input vectors
X_spots = inversions(1).T_inv * Y_spots;
clear Y_spots phase_factor;

% Create the mask-generating function
spot_function = @(n)input_to_slm(X_spots(:,n));

% Display the first spot
disp('Test spot is being displayed.');
d.show(spot_function(i_center));
shutter('distal','block');

                                          
%% Measurement
% Acquisition parameters
samples_per_period = 32;
period_per_spot = 6;


% Setup recording parameters
samplesPerPulse = 256;
pulsesPerFrame  = 3;
samplesPerFrame = samplesPerPulse*pulsesPerFrame;

vsyncRate = 59.936540749;
delayTime = 23917.92497267230e-6;
vsyncTime = 1/vsyncRate;
averagingTime = vsyncTime/16;
repeatTime = vsyncTime/4;


% Setup DirectX-linked pulses
d.setConfig('pulseNumber', pulsesPerFrame);
d.setConfig('pulseSync', true);
d.setConfig('pulseHighTime', 100e-6);
d.setConfig('pulseLowTime', repeatTime-d.getConfig('pulseHighTime'));
d.setConfig('pulseDelayTime', max(20e-9,delayTime-averagingTime/2));
d.setConfig('pulseDelayFrames', 4);

% Setup voltage recording
clear chan;
chan = DAQmxAnalogInput('Dev1/ai0','RSE',0,V_range);
chan.CfgSampClkTiming('',samplesPerPulse/averagingTime,'rising','finite',samplesPerPulse);
chan.CfgDigEdgeStartTrig('/Dev1/PFI12','rising');
chan.StartTriggerRetriggerable = true;
chan.InputBufferSize = samplesPerFrame*(N_spots+1);
start(chan);

% Measurement
shutter('distal','block');
shutter('proximal','open');
d.setConfig('pulseEnable', true);
scan_stamp = clock;
scan_meas_stats =   measure_sequence(d, ...
                                     [], ...
                                     [], ...
                                     spot_function, ...
                                     N_spots);
d.setConfig('pulseEnable', false);
d.show(zeros(size(spot_function(1)),'uint8'));
shutter('distal','open');

% Read sensor
getdata(chan,samplesPerFrame);
V_sensor = zeros(samplesPerFrame,numel(y_range),numel(x_range),N_spots/(numel(y_range)*numel(x_range)));
for i=1:N_spots
    V_sensor((1+(i-1)*samplesPerFrame):(i*samplesPerFrame)) = getdata(chan,samplesPerFrame);
end
stop(chan);
V_avg = shiftdim(mean(V_sensor,1),1);

% Plot if possible
if sum(size(V_avg)>1)==1
    if size(V_avg,3)>1
        plot(distance/1e-6, squeeze(V_avg));
    else
        plot(squeeze(V_avg));
    end
elseif sum(size(V_avg)>1)==2
    if size(V_avg,3)==1
        imagesc(squeeze(V_avg));
    else
        imagesc(squeeze(V_avg).');
    end
    colormap gray;
    axis image;
    axis off;
else
    for i=1:min(3,size(V_avg,3))
        figure;
        imagesc(V_avg(:,:,i));
        title(['Distance: ' num2str(distance(i)/1e-6) '\mum']);
        colormap gray;
        axis image;
        axis off;
    end
end

%% Save
scan_stamp_str = [num2str(scan_stamp(1)) '-' num2str(scan_stamp(2),'%02d') '-' num2str(scan_stamp(3),'%02d') ' ' num2str(scan_stamp(4),'%02d') '-' num2str(scan_stamp(5),'%02d') '-' num2str(round(scan_stamp(6)),'%02d')];
scan_str_file = input('Give a name to this dataset: ','s');
save2(['./data/' scan_stamp_str ' ' scan_str_file '.mat'],...
       'V_sensor','V_avg','pos','px','py','distance','x_range','y_range',...
	   'scan_stamp','scan_stamp_str','scan_str_file',...
       'N_spots','scan_meas_stats',...
       'mask_lin_pos','Nx','Ny',...
       'slm_params','holo_params',...
       'samples_per_spot','period_per_spot','samples_per_period',...
       'samplesPerPulse','pulsesPerFrame','samplesPerFrame','vsyncRate',...
       'delayTime','vsyncTime','averagingTime','repeatTime',...
       '/list-saved');





