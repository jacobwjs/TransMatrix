% This function is used to calculate the enhancement of a focus spot imaged
% onto a CCD camera. This code is largely based on the work of Damien Loterie
% from the file 'script_hdr_analyze3.m'.
% - Jacob Staley (March, 2016)
%
% Update to return pwercentage of power in the focus spot. I am not
% responsable for future changes.
% - Nico Stasio (March, 2016)
%
%
% Inputs:
% ----------------------------------------
% 'img_b'  => Finish me
% 'img_a'  => Finish me
%
% Outputs:
% ----------------------------------------
% 'enhancement'       => The ratio of the max intensity in the focal spot
%                        to the mean intensity in the background.
% 'enhancement_image' => The image that was used in the calculation of the
%                        enhancement. We return it to the user in case
%                        further processing is wanted.
% 'enhancement_pow'   => The ratio between the power in the focus over the total power.

function [enhancement, enhancement_image, enhancement_pow] = calculate_enhancement(img_a, img_b)

% Filter and normalize levels
img = img_b/max(img_b(:));
img(isnan(img)) = 0;

% Divide the result by the total intensity.
img = img./sum(abs(img(:)));

% Select the region of the fiber in the image. This provides the radius (in
% pixels) and location of the center of the fiber (in pixels) in the HDR
% image.
% Also, we remap the colorspace of the image for better visualization.
remapped_img = ind2rgb(1+round(db(img_a)/35 * 255), labview);
display('Press any key to select the region of interest of the fiber...');
pause;
fiber_attributes = holography_cal_circles(remapped_img);

% Take the average of the radii found selecting the ROI of the fiber.
avg_fiber_radius = (fiber_attributes.r1 + fiber_attributes.r2)/2;
r_fiber = avg_fiber_radius;

% Create a mask of the fiber based on the selection.
mask_fiber = mask_circular(size(img), ...
                           fiber_attributes.xc, ...
                           fiber_attributes.yc, ...
                           r_fiber);
% FIXME:
% - What is this?
homogeneous_level = 1/(pi*r_fiber.^2);

% Grid
xt = size(img, 2);
yt = size(img, 1);
[X,Y] = meshgrid(1:xt, 1:yt);

% Find center of the spot and sort pixels by radius.
display('Press any key to select the region of interest of the spot...');
pause;
spot_attributes = holography_cal_circles(remapped_img);
%[~,xm,ym] = maxnd(img,[2 1]);
%avg_spot_radius = (fiber_attributes.r1 + fiber_attributes.r2)/2;
mask_spot = mask_circular(size(img),...
                          spot_attributes.xc,...
                          spot_attributes.yc,...
                          spot_attributes.r2);
                      
I = img(mask_spot);
xI = X(mask_spot);
yI = Y(mask_spot);

I = I-min(I);
xIm = sum(xI.*I)./sum(I);
yIm = sum(yI.*I)./sum(I);

R = sqrt((X-xIm).^2 + (Y-yIm).^2);
[R_sorted, ind_img] = sort(R(:),'ascend');
area_img_sorted = pi*R_sorted.^2;

% Find fiber
% img_temp = img;
% img_temp = img_temp.*(img_temp>1.5*homogeneous_level);
% img_temp_rim = bwperim(img_temp>0);
% [Py,Px] = find(img_temp_rim);
% [x0_fiber, y0_fiber, ~] = mincircle_sqp([Px,Py]);
x0_fiber = fiber_attributes.xc; %holo_params.fiber.x;
y0_fiber = fiber_attributes.yc; %holo_params.fiber.y;



% Cumulative enclosed energy versus radius
% enclosed_energy = img(ind_img);
% enclosed_energy = cumsum(enclosed_energy);
% enclosed_energy = enclosed_energy./enclosed_energy(end);
% 
% % Simulation of the ideal background-free case
% airy = @(Ra)2*pi*Ra^2*jinc(Ra.*R);
% img_ref_field = airy(2*pi*48/800);
% img_ref_field = img_ref_field.*mask_circular(size(img_ref_field),...
%                                              x0_fiber,...
%                                              y0_fiber,...
%                                              r_fiber);
% img_ref = abs(img_ref_field).^2;
% img_ref = img_ref./sum(abs(img_ref(:)));
% 
% enclosed_energy_ref = img_ref(ind_img);
% enclosed_energy_ref = cumsum(enclosed_energy_ref);
% enclosed_energy_ref = enclosed_energy_ref./enclosed_energy_ref(end);


% % Plot
% close all;
% hf = figure;
% set(gcf,'Position',[250 250 560 360]);
% plot(R_sorted,enclosed_energy,'g','LineWidth',2); hold on;
% plot(R_sorted,enclosed_energy_ref,'k--','LineWidth',2);
% 
% % Rayleigh radius
% s = csapi(R_sorted,enclosed_energy);
% hold on;
% % xp=10; plot([xp xp 0],[0 fnval(s,xp) fnval(s,xp)],'r--','LineWidth',2);
% % xp=30; plot([xp xp 0],[0 fnval(s,xp) fnval(s,xp)],'r--','LineWidth',2);
% xp=10; plot([xp xp],[0 1],'r--','LineWidth',2);
% xp=30; plot([xp xp],[0 1],'r--','LineWidth',2);
% hold off;
% 
% % Labels
% hxl = xlabel('Radius [pixels]');
% % xlabel('Area [pixels]');
% hyl= ylabel('Enclosed energy');
% axis([0 50 0 1]);
% box off;
% set(gca,'YTickMode','manual');
% set(gca,'YTick',0:0.1:1);
% str = int2str(100*get(gca,'YTick').'); str(:,end+1)='%';
% set(gca,'YTickLabel',str);
% for h=[gca, hxl, hyl]
%     set(h,'FontName','Georgia');
%     set(h,'FontSize',14);
% end
% set(gca,'LineWidth',2);



% Mask out the portion of the fiber selected.
masked_image = img .* mask_fiber;
% Image in dB.
masked_image_dB = db(masked_image) - db(homogeneous_level);
figure, imagesc(masked_image_dB);
colormap(labview(256));
box off;
axis image;
axis off;
hc = colorbar;
CTick = [-20:10:70];
caxis([min(CTick) max(CTick)]);
set(hc,'YTick',CTick);
str = [num2str((CTick).')];
% Append the unit to the string on the colorbar. 
unit = 'dB';
str = [str, repmat([unit], [length(str), 1])];
set(hc,'YTickLabel',str);

%% Calculate the singal-to-background ratio (i.e. enhancement) in dB.
% Find the indices in the image that produced a contribution from
% everything in the fiber mask that produced an intensity value on the
% camera (i.e. spot + background).
indices_fiber_mask = find(masked_image_dB > -100);

% Find the indices of the focus spot in the image.
indices_focus_spot = find(mask_spot == 1);

% Remove the focus spot indices in order to calculate the contribution from
% the background.
[indices_remove, ~] = ismember(indices_fiber_mask,...
                               indices_focus_spot);
                           
% Remove the indices that are composed of the focus spot from the fiber mask,
% leaving only the background contribution.
indices_background = indices_fiber_mask;
indices_background(indices_remove) = [];

% Find the mean of the background intensity.
mean_background_intensity = mean(masked_image_dB(indices_background));
pow_background = sum(undb(masked_image_dB(indices_background)));

% Find the max in the focus spot.
max_focus_intensity = max(masked_image_dB(indices_focus_spot));
pow_focus = sum(undb(masked_image_dB(indices_focus_spot)));

% Calculate the final enhancement (no longer in dB).
enhancement = undb(max_focus_intensity)/undb(mean_background_intensity)
enhancement_pow = (pow_focus)/(pow_focus+pow_background)

% Convert the final image back from dB.
enhancement_image = undb(masked_image_dB);

% 
% % Non-masked presentation of intensity in the image.
% figure;
% imagesc(db(img));
% table = [0              0         0;
%          0.0353         0    0.7843;
%          0.0392    1.0000         0;
%          1.0000    0.9020         0;
%          1         1              1];
% 
% colormap(labview(256));
% % hold on; circle(x0_fiber,y0_fiber,r_fiber,'r'); hold off;
% box off;
% axis image;
% axis off;
% hc = colorbar;
% CTick = [-20:20:60 db(5000)];
% caxis([min(CTick) max(CTick)]);
% set(hc,'YTick',CTick);
% str = num2str(undb(CTick).'); str(:,end+1) = 'x';
% set(hc,'YTickLabel',str);
% 
% 
% % Writeout
% img_db = db(img)-db(homogeneous_level);
% img_db=(img_db+20)/(db(5000)+20);
% img_db(img_db<0)=0;
% img_db(img_db>1)=1;
% img_db = ind2rgb(round(1+255*img_db),labview(256));
% % imwrite(img_db,[stamp_str ' ' str_var '.png']);
% % saveas(hf,[stamp_str ' ' str_var ' graph.fig']);
% % saveas(hf,[stamp_str ' ' str_var ' graph.png']);



end