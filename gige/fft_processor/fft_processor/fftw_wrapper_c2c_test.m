% Demo script for the fftw_wrapper_c2c class.
%
%  - Damien Loterie (04/2015)

% Includes
addpath('../../../tm9');
% addpath('../../gige_interface/gige_interface');

% Load data
load('test_img.mat','img','maskf');
img = double(img) + 1i;

% Create transform object
f = fftw_wrapper_c2c(size(img,2),size(img,1));


% C++ transforms
ind_all  = mask_to_indices(true(size(img)),'fftshifted-to-fftw-c2c-transpose');
ind_mask = mask_to_indices(maskf,'fftshifted-to-fftw-c2c-transpose');
imgf  = f.transform(img.');

imgfa = reshape(imgf(1+abs(ind_all)),size(img));
imgfa(ind_all<0) = conj(imgfa(ind_all<0));

vmask = imgf(1+abs(ind_mask));
vmask(ind_mask<0) = conj(vmask(ind_mask<0));

% MATLAB transforms
imgm  = fft2s(img);
vmaskm = imgm(maskf);

% Figures
subplot(2,1,1);
imagesc(db(imgfa)); axis image; axis off;
subplot(2,1,2);
imagesc(db(imgm)); axis image; axis off;
