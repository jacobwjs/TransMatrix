function mask = mask_circular(dims, x0, y0, r)
	% mask = mask_circular(dims, x0, y0, r)
	% Function to create a circular mask with given dimensions.
	%  - Damien Loterie (05/2014)

	% Input processing
	width = dims(2);
	height = dims(1);
    if isempty(x0)
        [x0,y0] = center_of(width,height);
    end

	% Mask generation
    [X,Y] = meshgrid(1:width, 1:height);
    mask = ((X-x0).^2 + (Y-y0).^2) <= r^2;
end

