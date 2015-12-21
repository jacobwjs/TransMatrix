function img = modulation_slm(x_img, y_img, x, y)
    % img = modulation_slm(x_img, y_img, x, y)
    % Function to create linear phase gratings for the SLM.
    % The x and y coordinates correspond to coordinates in the
    % fft2 shifted domain. The returned image is transposed, i.e. ready to
    % be sent to the SLM.
    %   - Damien Loterie (07/2014)

    
    % Note: In this function, x and y are inverted w.r.t. the MATLAB 
    %       convention, because the SLM works that way.

    x = x - center_of(x_img);
    y = y - center_of(y_img);
    
    xmod = single(0:(x_img-1)).'/x_img;
    ymod = single(0:(y_img-1))/y_img;
    
    xmod = bsxfun(@times, xmod, reshape(x,[1 1 numel(x)]));
    ymod = bsxfun(@times, ymod, reshape(y,[1 1 numel(y)]));
    
    img = uint8(mod(256*bsxfun(@plus, xmod, ymod),256));

    % slm_to_matlab = @(frames)exp(2i*pi*double(permute(frames,[2 1 3]))/256);
end

