% Script to measure an HDR stack for spot enhancement characterization.
%  - Damien Loterie (04/2015)
%
% Small updates to the camera definition and initialization, as well as the
% synchronization behavior between camera and SLM, which is dependent on the SLM in use.
% - Jacob Staley (03/2016)


%% Initialization routines.
% Create the camera object if needed.
if ~exist('vid','var')
    display('Initializing camera...');
    %vid = camera_mex('distal', 'ElectronicTrigger');
    clear vid;
    vid = camera_mex(2);
end
offsetX_pixels = 160; % Must be multiples of 32.
offsetY_pixels = 50;
num_pixels_X   = 928; % Must be multiples of 32.
num_pixels_Y   = 928;
vid.ROIPosition = [offsetX_pixels offsetY_pixels...
                   num_pixels_X num_pixels_Y];

% Create the slm object if needed.
if ~exist('slm', 'var')
    display('Initializing SLM. Please update with an appropriate phase mask...');
    run_test_patterns = false;
    slm = slm_device('meadowlark', run_test_patterns);
end

% Because the HoloEye SLM's have a slow refresh of their pixels, it's possible
% to capture a frame from the camera that randomly samples the voltage rise
% and drop, which if we are projecting a spot results in a pulsing in the
% intensity. Therefore we must synchronize with the SLM. This is not needed
% with the Meadowlark however, due to its rapid refresh rate.
sync_flag = false;
if (isequal(slm.model, 'holoeye'))
    sync_flag = true;
end


% Decide exposure range. These exposures will be used to capture a
% frame from the camera. Capturing multiple frames removes the chance of
% flicker from the SLM (refresh rate), small pertubations of the system,
% etc. Basically it's a more robust way of making a measurement representative of
% the average statistics of the system.
exposures = round(20*(1.25.^(0:35)));
fprintf('Using %d exposures ranging from %d to %d usecs.\n', ...
        length(exposures), min(exposures), max(exposures));


% Acquire an image for each exposure with the reference path blocked (i.e.
% only the object path is open).
disp('Measuring HDR stack...');
shutter('distal','block');
stack_hdr = getsnapshotse(vid, exposures, [], sync_flag);

% Acquire the dark frames with both paths blocked (i.e. no reference, and
% no object path).
shutter('both','block');
disp('Measuring background stack...');
stack_bg = getsnapshotse(vid, exposures, [], sync_flag);
shutter('proximal','pass');



% 3-dimensional
stack_bg  = reshape(stack_bg(:,:,1,:),  [size(stack_bg,1) size(stack_bg,2) size(stack_bg,4)]);
stack_hdr = reshape(stack_hdr(:,:,1,:), [size(stack_hdr,1) size(stack_hdr,2) size(stack_hdr,4)]);

%% Calculation
disp('Calculating...');
% Background-free stack
y = double(stack_hdr) - double(stack_bg);
%y = double(stack_hdr);

% Find correctly exposed pixels
ind = (stack_hdr>(200+0.025*saturation_level)) & (stack_hdr<(0.95*saturation_level));

% Regression
[img_b, img_a, img_N] = hdr_fit(exposures, y, ind);

%% Check fit
x_test = center_of(size(img_a,2));
y_test = center_of(size(img_a,1));
ind_line = squeeze(ind(y_test,x_test,:));
t_line   = exposures(ind_line);
y_line   = squeeze(y(y_test,x_test,:)); y_line = y_line(ind_line);
b_line   = img_b(y_test,x_test);
a_line   = img_a(y_test,x_test);

figure;
subplot(2,2,1);
imagesc(db(img_b));

subplot(2,2,2);
imagesc(img_a);

subplot(2,2,3);
imagesc(img_N);

subplot(2,2,4);
plot(t_line,...
     y_line,'ro');
hold on;
plot(t_line,...
     b_line.*t_line + a_line,'k');
hold off;


%% Save data
% Pick best frame, for reference.
num_sat = squeeze(sum(sum(stack_hdr>0.95*saturation_level,2),1));
ind_best = find(num_sat==0,1,'last');
frame          = squeeze(stack_hdr(:,:,ind_best));
frame_bg       = squeeze(stack_bg(:,:,ind_best));
frame_exposure = exposures(ind_best);


% Calculate the enhancement of the spot relative to the background. That
% is, find the intensity in the focus spot relative the the background
% (speckle in the image).
[enhancement, image, percentage_pow_focus] = calculate_enhancement(img_a, img_b);



% % Save
% stamp = clock;
% stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];
% if ~exist('./data/','dir')
%     mkdir('./data/');
% end
% str_file = input('Give a name to this dataset: ','s');
% name_of_script = mfilename;
% save2(['./data/' stamp_str ' ' str_file '.mat'],...
% 	   'img_a','img_b','img_N','stamp','str_file','name_of_script',...
%        'slm_params','prox_params','align_params','new_align_params','xm',...
%        'dx_options','field_slm','hologram','field',...
%        'frame','frame_bg','frame_exposure','exposures',...
%        'field_slm_gs','mask_pol_gs',...
%        'ref_spot_frame','ref_spot_exposure');
% disp('Data saved.');





