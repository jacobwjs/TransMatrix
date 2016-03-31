% Script to analyze an HDR stack (contrast, enhancement,...)
%  - Damien Loterie (08/2015)

% Filter and normalize levels
img = img_b/max(img_b(:));
img(isnan(img)) = 0;

% Divide the result by the total intensity.
img = img./sum(abs(img(:)));

% Select the region of the fiber in the image. This provides the radius (in
% pixels) and location of the center of the fiber (in pixels) in the HDR
% image.
fiber_attributes = holography_cal_circles(img_a);
% Take the average of the radiu's.
r_fiber = (fiber_attributes.r1 + fiber_attributes.r2)/2;
homogeneous_level = 1/(pi*r_fiber.^2);

% Grid
xt = size(img, 2);
yt = size(img, 1);
[X,Y] = meshgrid(1:xt, 1:yt);

% Find center and sort pixels by radius
[~,xm,ym] = maxnd(img,[2 1]);
mask_spot = mask_circular(size(img),xm,ym,12);
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
y0_fiber = fiber_attributes.xy; %holo_params.fiber.y;

% Enhancement
enhancement = max(img(:))/mean(img(:));

% Cumulative enclosed energy versus radius
enclosed_energy = img(ind_img);
enclosed_energy = cumsum(enclosed_energy);
enclosed_energy = enclosed_energy./enclosed_energy(end);

% Simulation of the ideal background-free case
airy = @(Ra)2*pi*Ra^2*jinc(Ra.*R);
img_ref_field = airy(2*pi*48/800);
img_ref_field = img_ref_field.*mask_circular(size(img_ref_field),x0_fiber,y0_fiber,r_fiber);
img_ref = abs(img_ref_field).^2;
img_ref = img_ref./sum(abs(img_ref(:)));

enclosed_energy_ref = img_ref(ind_img);
enclosed_energy_ref = cumsum(enclosed_energy_ref);
enclosed_energy_ref = enclosed_energy_ref./enclosed_energy_ref(end);

% Plot
close all;
hf = figure;
set(gcf,'Position',[250 250 560 360]);
plot(R_sorted,enclosed_energy,'g','LineWidth',2); hold on;
plot(R_sorted,enclosed_energy_ref,'k--','LineWidth',2);

% Rayleigh radius
s = csapi(R_sorted,enclosed_energy);
hold on;
% xp=10; plot([xp xp 0],[0 fnval(s,xp) fnval(s,xp)],'r--','LineWidth',2);
% xp=30; plot([xp xp 0],[0 fnval(s,xp) fnval(s,xp)],'r--','LineWidth',2);
xp=10; plot([xp xp],[0 1],'r--','LineWidth',2);
xp=30; plot([xp xp],[0 1],'r--','LineWidth',2);
hold off;

% Labels
hxl = xlabel('Radius [pixels]');
% xlabel('Area [pixels]');
hyl= ylabel('Enclosed energy');
axis([0 50 0 1]);
box off;
set(gca,'YTickMode','manual');
set(gca,'YTick',0:0.1:1);
str = int2str(100*get(gca,'YTick').'); str(:,end+1)='%';
set(gca,'YTickLabel',str);
for h=[gca, hxl, hyl]
    set(h,'FontName','Georgia');
    set(h,'FontSize',14);
end
set(gca,'LineWidth',2);




% Images
figure;
imagesc(db(img)-db(homogeneous_level));
table = [0              0         0;
         0.0353         0    0.7843;
         0.0392    1.0000         0;
         1.0000    0.9020         0;
         1         1              1];

colormap(labview(256));
% hold on; circle(x0_fiber,y0_fiber,r_fiber,'r'); hold off;
box off;
axis image;
axis off;
hc = colorbar;
CTick = [-20:20:60 db(5000)];
caxis([min(CTick) max(CTick)]);
set(hc,'YTick',CTick);
str = num2str(undb(CTick).'); str(:,end+1) = 'x';
set(hc,'YTickLabel',str);


% Writeout
img_db = db(img)-db(homogeneous_level);
img_db=(img_db+20)/(db(5000)+20);
img_db(img_db<0)=0;
img_db(img_db>1)=1;
img_db = ind2rgb(round(1+255*img_db),labview(256));
% imwrite(img_db,[stamp_str ' ' str_var '.png']);
% saveas(hf,[stamp_str ' ' str_var ' graph.fig']);
% saveas(hf,[stamp_str ' ' str_var ' graph.png']);