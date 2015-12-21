function data = reconstruct_half(data, mask_in)
    % A reconstruction function for off-axis digital holography.
    % Retrieves the relevant pixels in the Fourier domain.
    %
    % /!\ Warning /!\
    % This function assumes mask_in does not span over multiple quadrants.
    %
    % - Damien Loterie (08/2014)

    % Fourier transform
    data = fft2(double(squeeze(data)))/(saturation_level);
 
    % Mask
    data = mask(data, ifftshift2(mask_in));
end

