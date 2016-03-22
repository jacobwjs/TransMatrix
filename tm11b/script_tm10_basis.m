% Script defining the input and output bases for the transmission matrix measurement
%  - Damien Loterie (08/2015)

% [INPUT BASIS]
% Mask to convert between 1D input vectors and 2D input images displayable in MATLAB
mask_input = slm_params.freq.mask1;

% Input basis used to create the transmission matrix
[input_function, input_size, input_unitary] = basis_unit(sum(mask_input(:)));

% Precalculated indices to speed up the input_to_slm function
mask_input_lin = mask_to_indices(slm_params.freq.mask1, 'fftshifted-to-fft-transpose');

% Convert input basis 1D vectors to 8-bit SLM phases
input_to_slm = @(v)phase_slm_fast(ifft2(unmask_linear(single(v),mask_input_lin,size(mask_input))));

% Convert SLM phases back to input basis 1D vectors
% (this is needed during the validation step)
slm_to_input = @(frames)mask(fftshift2(fft2(exp(2i*pi*double(permute(frames,[2 1 3]))/256))),mask_input);

% Convert input basis 1D vectors to FFT-domain image (for SVD plot)
input_to_fft = @(v)unmask(v, clip_mask(mask_input));

% Convert input basis 1D vectors to field images (for SVD plot)
input_to_field = @(v)ifft2(ifftshift2(unmask(v, slm_params.freq.mask1c)));

% Convert field images to 1D input vectors
field_to_input = @(fields)mask(fftshift2(fft2(fields)), slm_params.freq.mask1c);

% [RECONSTRUCTION & OUTPUT BASIS]
% Convert field images to 1D output vectors
field_to_output = @(fields)mask(fftshift2(fft2(fields)), holo_params.freq.mask1c);

% Convert 1D output vectors to field images (for visualization and SVD plot)
output_to_field = @(v)ifft2(ifftshift2(unmask(v, holo_params.freq.mask1c)));

% Convert camera images to 1D output vectors
camera_to_output = @(frames)mask(fftshift2(fft2(frames)), holo_params.freq.mask1);

% Convert camera images to field images
camera_to_field = @(frames)output_to_field(camera_to_output(frames));

% Convert output basis 1D vectors to FFT-domain image (for SVD plot)
output_to_fft = @(v)unmask(v, clip_mask(holo_params.freq.mask1c));
