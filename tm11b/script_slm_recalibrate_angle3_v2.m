% Script to find the right fiber positions on the SLM
% - Damien Loterie (07/2014)

%% Initialize
% Cleanup
reset_all

% Identify script
name_of_script = mfilename;

% % No reference needed
% shutter('distal','block');
display('Block the reference path. Not needed for this measurement');

% %% Configure fullscreen, camera and holography
% % Fullscreen parameters
% [x_slm, y_slm] = slm_size();
% params_old = slm_getcal();
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);
pause(0.25);

x_slm = slm.x_pixels;
y_slm = slm.y_pixels;

% ROI = params_old.ROI;
ROI = [0 0 x_slm y_slm];

% % Open fullscreen window
% addpath(dx_fullscreen_path);
% dx_options = struct('monitor',      1,...
%                     'screenWidth',  x_slm,...
%                     'screenHeight', y_slm,...
%                     'frameWidth',   ROI(3),...
%                     'frameHeight',  ROI(4),...
%                     'renderWidth',  ROI(3),...
%                     'renderHeight', ROI(4),...
%                     'renderPosX',   ROI(1),...
%                     'renderPosY',   ROI(2));
% d = dx_fullscreen(dx_options);


% Initialize the camera
% ---------------------------------------------------------------
clear vid;
vid = camera_mex('distal','ElectronicTrigger');
vid.ROIPosition = [352 208 608 608];


%% Search parameters
% exposure = 75*2;
exposure = 2000;
coarse_grid_spacing_pct = 0.025;
fine_grid_spacing_pct = 0.0025;
fine_grid_range_pct = 0.200;
skip_fine = true;

%% Coarse search
% Configure sequence
grid_spacing_x = coarse_grid_spacing_pct * ROI(3);
grid_spacing_y = coarse_grid_spacing_pct * ROI(4);
x_grid = (grid_spacing_x/2):grid_spacing_x:ROI(3);
y_grid = (grid_spacing_y/2):grid_spacing_y:ROI(4);
xy_grid = combvec(x_grid, y_grid).';

sequence_function = @(n)modulation_slm_fast(int32(ROI(3)),...
                                            int32(ROI(4)),...
                                            int32(xy_grid(n,1)),...
                                            int32(xy_grid(n,2)));
number_of_frames = size(xy_grid,1);

% % Measurement
% measurement_stats = measure_sequence(d, ...
%                                      vid, ...
%                                      exposure, ...
%                                      sequence_function, ...
%                                      number_of_frames);

% Measurement
[frames, measurement_stats] = measure_sequence_v2(slm, ...
                                                    vid, ...
                                                    exposure, ...
                                                    sequence_function, ...
                                                    number_of_frames, ...
                                                    holo_params.freq.mask1);  

% Processing
data = getdata(vid, number_of_frames);
data_red = squeeze(sum(sum(data,1,'double'),2,'double'));
data_max = squeeze(max(max(data,[],1),[],2));
clear data;

% Check exposure before continuing
if sum(data_max>=saturation_level)>(0.03*number_of_frames)
    error('A significant number of frames were over-exposed.');
end
if max(data_max)<0.25*saturation_level
    error('The exposure is too low, or the fiber was not found.');
end

% Find maximum
[~,i_max] = max(data_red);
x_max = xy_grid(i_max,1);
y_max = xy_grid(i_max,2);

% Interpolate
[Xd,Yd] = meshgrid(x_grid,y_grid);
[Xi,Yi] = meshgrid(1:ROI(3),1:ROI(4));
img_full = interp2(Xd,Yd,reshape(data_red,[numel(x_grid) numel(y_grid)])',Xi,Yi);
imagesc(img_full);

% img_full = zeros([ROI(4) ROI(3)]);
% s = csapi({x_grid, y_grid},reshape(data_red,[numel(x_grid) numel(y_grid)]));
% [X,Y] = meshgrid(1:ROI(4),1:ROI(3));
% img_full(:) = fnval(s,[X(:),Y(:)].');
% imagesc(img_full);

% Find fiber
img_color = ind2rgb(1+round(255*rescale(img_full)),gray(256));
params_coarse = holography_cal_circles(img_color,...
                                       x_max,...
                                       y_max,...
                                       params_old.freq.r1*ROI(3)/params_old.ROI(3),...
                                       params_old.freq.r2*ROI(3)/params_old.ROI(3));


%% Fine search
if ~skip_fine
    % Configure sequence
    grid_spacing_x = ceil(fine_grid_spacing_pct * ROI(3));
    grid_spacing_y = ceil(fine_grid_spacing_pct * ROI(4));
    grid_range_x = fine_grid_range_pct * ROI(3);
    grid_range_y = fine_grid_range_pct * ROI(4);
    x_grid2 = (max(1,round(x_max-grid_range_x/2)):grid_spacing_x:min(round(x_max+grid_range_x/2),ROI(3)));
    y_grid2 = (max(1,round(y_max-grid_range_y/2)):grid_spacing_y:min(round(y_max+grid_range_y/2),ROI(4)));
    xy_grid2 = combvec(x_grid2, y_grid2).';

    sequence_function = @(n)modulation_slm_fast(int32(ROI(3)),...
                                                int32(ROI(4)),...
                                                int32(xy_grid2(n,1)),...
                                                int32(xy_grid2(n,2)));
    number_of_frames = size(xy_grid2,1);

    % Measurement
    measurement_stats2 = measure_sequence(d, ...
                                          vid, ...
                                          exposure, ...
                                          sequence_function, ...
                                          number_of_frames);

    % Processing
    data = getdata(vid, number_of_frames);
    data_red2 = squeeze(sum(sum(data,1,'double'),2,'double'));
    data_max2 = squeeze(max(max(data,[],1),[],2));
    clear data;

    % Interpolate
    % s2 = csapi({x_grid2, y_grid2},reshape(data_red2,[numel(x_grid2) numel(y_grid2)]));

    % Interpolate
    [Xd2,Yd2] = meshgrid(x_grid2,y_grid2);
    mask2 = Xi>=min(x_grid2) & Xi<=max(x_grid2) & Yi>=min(y_grid2) & Yi<=max(y_grid2);
    Xi2 = Xi(mask2);
    Yi2 = Yi(mask2);
    Xi2 = reshape(Xi2,[max(Yi2(:))-min(Yi2(:))+1 max(Xi2(:))-min(Xi2(:))+1]);
    Yi2 = reshape(Yi2,[max(Yi2(:))-min(Yi2(:))+1 max(Xi2(:))-min(Xi2(:))+1]);

    img_sub = interp2(Xd2,Yd2,reshape(data_red2,[numel(x_grid2) numel(y_grid2)])',Xi2,Yi2);
    img_full2 = img_full;
    img_full2(mask2) = img_sub;

    % Find fiber
    img_test = ind2rgb(1+round(255*rescale(img_full2)),gray(256));
    params_fine = holography_cal_circles(img_test, ...
                                         params_coarse.xc,...
                                         params_coarse.yc,...
                                         params_coarse.r1,...
                                         params_coarse.r2);
else
   params_fine = params_coarse; 
end

%% Record new calibration
slm_params = struct();
slm_params.ROI = ROI;
slm_params.freq.x = round(params_fine.xc);
slm_params.freq.y = round(params_fine.yc);
slm_params.freq.r1 = round(params_fine.r1);
slm_params.freq.r2 = round(params_fine.r2);
slm_params.fiber.x = center_of(ROI(3));
slm_params.fiber.y = center_of(ROI(4));
slm_params.fiber.r1 = 383;
slm_params.fiber.r2 = 400;

str = input('Update the SLM calibration [y/n]? ','s');
if strcmpi(str,'y')
    slm_setcal(slm_params);
    disp('The new SLM calibration was saved');
else
    disp('Aborted.')
end


