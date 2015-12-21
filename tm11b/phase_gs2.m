function [slm_img, stats] = phase_gs2(field, mask_freq, iterations, mask_spatial)
	%  - Damien Loterie (05/2014)
	
    % Normalize
    field = field./sqrt(mean(abs(field(:).^2)));

    % Prepare iterations
    slm = field;
    slm_fft = fftshift(fft2(slm));
    source_fft_piece = slm_fft(mask_freq);

    % Gerchberg-Saxton
    ticID = tic;
    for i=1:iterations
        % Fourier constraint:
        % The spatial frequencies that will end up in the fiber (i.e. the
        % spatial frequencies within the mask) must match those of the desired
        % intensity pattern.
        slm_fft(mask_freq) = source_fft_piece;
        slm = ifft2(ifftshift(slm_fft));

        % Spatial constraint:
        % The mask must be phase-only
        slm_abs = abs(slm);
        mean_abs = mean(slm_abs(:));
        slm = 0.99*mean_abs*slm./slm_abs;

        % Fourier transform
        slm_fft = fftshift(fft2(slm));
    end
    
    % Renormalize absolute value
    slm = slm./abs(slm);
    
    % Analyze
    if nargout>1
        % Time
        stats = struct();
        stats.time = toc(ticID);

        % Correlation
        target = ifft2(ifftshift(slm_fft.*mask_freq));
        stats.correlation = corr2c(field(mask_spatial), target(mask_spatial));

        % Check if it is phase-only
        slm_abs = abs(slm);
        stats.abs_min = min(slm_abs(:));
        stats.abs_max = min(slm_abs(:));
        stats.abs_diff = stats.abs_max - stats.abs_min;

        % Diffraction efficiency
        Ein = sum(sum(abs(slm_fft).^2.*mask_freq));
        Eall = sum(sum(abs(slm_fft).^2));
        stats.eff = Ein/Eall;
    end
    
    % Make 8-bit phase mask
    slm_img = phase_slm(slm);
end
