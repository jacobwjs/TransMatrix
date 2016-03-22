function mask = mask_square(dims, x0, y0, L)
	% mask = mask_circular(dims, x0, y0, L)
	% Function to create a square mask with given dimensions.
	%  - Damien Loterie (05/2014)

	% Input processing
	width = dims(2);
	height = dims(1);
    if isempty(x0)
        [x0,y0] = center_of(width,height);
    end

	% Mask generation
    [X,Y] = meshgrid(1:width, 1:height);
    mask = abs(X-x0)<=(L/2) & abs(Y-y0)<=(L/2);
end

