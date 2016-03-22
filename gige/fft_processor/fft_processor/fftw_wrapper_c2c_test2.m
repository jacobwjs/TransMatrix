% Demo script for the fftw_wrapper_c2c class.
%
%  - Damien Loterie (04/2015)

% Includes
addpath('../../../tm11b');
% addpath('../../gige_interface/gige_interface');

% Load data
load('test_img.mat','img','maskf');
img = double(img);

% Create transform object
f = fftw_wrapper_c2c(size(img,2),size(img,1));

% Fourier transform
imgf = fft2s(img);
imgf_v = imgf(maskf);

% C++ transforms
iter = 1;
ind_mask = mask_to_indices(maskf,'fftshifted-to-fftw-c2c-transpose');
img_gs  = f.gerchberg_saxton(imgf_v, ind_mask, iter);

% MATLAB comparison
img_m  = slm_to_matlab(phase_gs2(ifft2(ifftshift2(unmask(v,maskf))),maskf,iter));

% Figures
subplot(2,1,1);
imagesc(db(img_gs)); axis image; axis off;
subplot(2,1,2);
imagesc(db(img_m)); axis image; axis off;
