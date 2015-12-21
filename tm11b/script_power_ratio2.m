% Script to get maximal SNR in the diffracted order (for holography)
% This updated version calculates the SNR, which is a more meaningful
% measurement than the power alone.
% - Damien Loterie (10/2014)
%
% Note: We assume the a representative pattern is being shown.
%


% Configure holography
clear vid_test;
% vid_test = camera_mex(1);
vid_test = camera_mex(2);
% vid_test = vid_prox;
% vid_test = vid;
shutter('reset');
[test_params, test_img] = holography_calibration(vid_test);
[~,DeviceID,~] = camera2name(test_params.DeviceName);

% test_params = slm_params;

% Measure FPN
shutter('both','block');
stack = getsnapshotse(vid_test,(0.5:0.1:1.5)*test_params.exposure);
bg = squeeze(mean(double(stack),4));
shutter('both','open');

% Start video
start(vid_test);

% Prepare figure
h_fig = figure;
set(h_fig, 'KeyPressFcn', @script_power_ratio_key)
set(h_fig, 'Name', 'SNR optimization')

% Loop
snr_max = 0;
exposure = test_params.exposure;
mask_in = ifftshift2(test_params.freq.mask2);
mask_DC = ifftshift2(mask_circular(size(bg),[],[],125));

% Find a region with only background noise
frame = double(test_img) - bg;
frame_fft = fft2(frame);
frame_fft_map = imdilate(fftshift2(abs(frame_fft).^2), clip_mask(mask_in)>0.5);
frame_fft_map((1:size(frame_fft_map,1))<=test_params.freq.r2,:) = NaN;
frame_fft_map((1:size(frame_fft_map,1))>=(size(frame_fft_map,1)-test_params.freq.r2),:) = NaN;
frame_fft_map(:,(1:size(frame_fft_map,2))<=test_params.freq.r2) = NaN;
frame_fft_map(:,(1:size(frame_fft_map,2))>=(size(frame_fft_map,2)-test_params.freq.r2)) = NaN;
[~,y_noise,x_noise] = minnd(frame_fft_map,[1 2]);
mask_noise = ifftshift2(mask_circular(size(bg),x_noise,y_noise,test_params.freq.r2));

% Start automated routine
enable_pid = true;
pct_target = 0.85;
hp1 = [];

while ishandle(h_fig) && ~strcmpi(get(h_fig,'Name'),'Closing...')
   % Get frame
   triggere(DeviceID, exposure, [], 1, true);
   frame = getdata(vid_test,1);
   exposure_old = exposure;
   
   % Auto exposure
   I_max = quantile(frame(:),1-10/numel(frame));
   I_mean = mean(frame(:));
   if enable_pid
        pct_meas = double(squeeze(I_max))/saturation_level;
        if pct_meas<1
            factor_corr = min(4,pct_target/pct_meas);
        else
            factor_corr = 1-1.5*(1-pct_target);
        end
        exposure = factor_corr*exposure;
   end
   
   % Background correction
   frame = double(frame) - bg;
   
   % Calculate SNR
   frame_fft = fft2(frame);
   snr = db(sum(abs(frame_fft(mask_in)).^2)/sum(abs(frame_fft(mask_noise)).^2));
   if (snr>snr_max)
       snr_max = snr;
   end

   % Draw
   x  = [0,0,1,1];
   y1 = snr*[0,1,1,0];
   y2 = snr + (snr_max-snr)*[0,1,1,0];
   ye1 = double(I_max)*[0,1,1,0];
   ye2 = double(I_mean)*[0,1,1,0];
   lim_up = ceil(snr_max/10)*10;
   exp_str = ['Exposure: ' int2str(exposure_old) '\mus'];
   imgdata = db(fftshift2(frame_fft));
   if isempty(hp1)
       figure(h_fig);

       hax1 = subplot(1,3,1);
       hp1 = patch(x,y1,hsv2rgb([0.3 0.9 0.95]));
       hp2 = patch(x,y2,hsv2rgb([0 0.8 0.95]));

       axis([-1 2 0 lim_up]);
       xlabel('SNR of the 1st order [dB]');
       set(gca,'XTick',[]);

       hax2 = subplot(1,3,2);
       hpe1 = patch(x,ye1,'b');
       hpe2 = patch(x,ye2,'c');
       htxt = text(1,saturation_level,...
                exp_str,...
                'VerticalAlignment','top',...
                'HorizontalAlignment','center',...
                'FontSize',8);

       axis([-1,2,0,saturation_level+1]);
       xlabel('Max. pixel [camera units]');
       set(gca,'XTick',[]);
       set(gca,'YTick',(0:0.25:1)*(saturation_level+1));

       hax3 = subplot(1,3,3);
       h_img = image(imgdata,'CDataMapping','scaled');
       colormap labview;
       axis image;
       axis off;
       caxis([80 140]);
       hc1 = circle(test_params.freq.x,test_params.freq.y,test_params.freq.r2,'w');
       hc2 = circle(x_noise,y_noise,test_params.freq.r2,'w');
       
       set(h_fig, 'Units', 'Pixels');
       set(h_fig,'Position',[100 200 1000 700]);
       set(hax1, 'Units', 'Normalized');
       set(hax1,'Position',[0.05 0.1 0.2 0.8]);
       set(hax2, 'Units', 'Normalized');
       set(hax2,'Position',[0.3 0.1 0.2 0.8]);
       set(hax3, 'Units', 'Normalized');
       set(hax3,'Position',[0.55 0.1 0.4 0.8]);
   else
       v = get(hp1,'Vertices'); v(:,2) = y1(:); set(hp1,'Vertices',v);
       v = get(hp2,'Vertices'); v(:,2) = y2(:); set(hp2,'Vertices',v);
       v = get(hpe1,'Vertices'); v(:,2) = ye1(:); set(hpe1,'Vertices',v);
       v = get(hpe2,'Vertices'); v(:,2) = ye2(:); set(hpe2,'Vertices',v);
       set(htxt,'String',exp_str);
       set(h_img,'CData',imgdata);
       axes(hax1); axis([-1 2 0 lim_up]); %#ok<LAXES>
   end

   
   % Pause
   pause(0.001);
end
stop(vid_test);
if ishandle(h_fig)
    close(h_fig);
end
clear vid_test;