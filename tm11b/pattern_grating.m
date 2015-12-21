function img = pattern_grating(mask_fiber, dx, dy)
    % PATTERN_GRATING Creates a linear grating test pattern
	%  - Damien Loterie (05/2014)
    
    % Input processing
    if isnumeric(mask_fiber) && numel(mask_fiber)==2
        dims = reshape(mask_fiber,[1,2]);
        windowing = false;
    else
        dims = size(mask_fiber);
        windowing = true;
    end
    
    % Calculate DC coordinates
	[x0,y0] = center_of(dims(2),dims(1));
    
    % Grating
    img = zeros(dims);
    img(sub2ind(size(img), y0+dy, x0+dx)) = 1;
    img = ifft2(ifftshift2(img));
    img = img./max(abs(img(:)));
    
    % Windowing
    if windowing
        img = img.*mask_fiber;
    end
end

