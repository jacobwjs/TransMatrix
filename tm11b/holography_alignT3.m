% Script to align the SLM and holography based on TM results
%   - Damien Loterie (08/2015)
	
tic;
Ttemp = real(T).^2 + imag(T).^2;
avg1 = mean(Ttemp,1);
avg2 = mean(Ttemp,2);
clear Ttemp;

imgfft1 = unmask(avg1,mask_input);
imgfft2 = unmask(avg2,holo_params.freq.mask1);
toc;

%%
[xc,yc] = center_of(size(mask_input,2),size(mask_input,1));
dx0 = xc - slm_params.freq.x;
dy0 = yc - slm_params.freq.y;
mask_inputc = abs(move_xy(mask_input,dx0,dy0))>0.5;

%%
tic;
n_sel = 100;
sel1 = T(randi(size(T,1),n_sel,1),:)';
sel2 = T(:,randi(size(T,2),1,n_sel));

stack1 = ifft2(ifftshift2(unmask(sel1, mask_inputc)));
stack2 = ifft2(ifftshift2(unmask(sel2, holo_params.freq.mask1c)));

img1 = sqrt(mean(real(stack1).^2 + imag(stack1).^2,3));
img2 = sqrt(mean(real(stack2).^2 + imag(stack2).^2,3));

clear sel1 sel2 stack1 stack2;
toc;

[xslm, yslm] = slm_size();
img1_full = ROI_place(img1, zeros(yslm,xslm), slm_params.ROI);

[xcam, ycam] = camera_size();
img2_full = ROI_place(img2, zeros(ycam,xcam), holo_params.ROI);

%%

slm_params2 = holography_calibration(img1_full, imgfft1, slm_params, 'no save');
holo_params2 = holography_calibration(img2_full, imgfft2, holo_params);

%%
if any([(slm_params2.ROI(1)+slm_params2.fiber.x) ~= (slm_params.ROI(1)+slm_params.fiber.x) ...
        (slm_params2.ROI(2)+slm_params2.fiber.y) ~= (slm_params.ROI(2)+slm_params.fiber.y) ...
        slm_params2.freq.x  ~= slm_params.freq.x  ...
        slm_params2.freq.y  ~= slm_params.freq.y])
    
    clc;
    str = input('Update the SLM calibration [y/n]? ','s');

    if strcmpi(str,'y')
            slm_setcal(slm_params2);
            disp('The new SLM calibration was saved');
    else
        disp('Aborted.')
    end

else
   disp('There is no difference with the already stored calibration.'); 
end
disp(' ');

