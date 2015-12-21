function data = reconstruct_simple(data, mask_in, mask_out)
    % A simplified reconstruction function for off-axis digital holography.
    % The masks must be determined in advance with holography_calibration.
    % Can operate on one or many frames.
    % - Damien Loterie (01/2014)

    % Fourier transform
    F = fftshift2(fft2(double(squeeze(data)))) ...
         /(saturation_level);
 
    % Mask
    if nargin>=3
       % Different input & output masks require a copy
       F = unmask(F(repmat(mask_in,[1 1 size(F,3)])), mask_out);
       
%        % Old code
%        mask_out_rep = repmat(mask_out,[1 1 size(F,3)]);
%        F(mask_out_rep) = F(repmat(mask_in,[1 1 size(F,3)]));
%        F(~mask_out_rep) = 0;
%        clear mask_out_rep;
    else
       % This operation is faster for equal input and output masks
       F = bsxfun(@times,F,mask_in);
    end
    
    % Inverse Fourier transform
    data = ifft2(ifftshift2(F));
end

