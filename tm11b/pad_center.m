function img_out = pad_center(img_in, size_out, offset)
    % Places the input image inside a black canvas with given size
    % Also allows for an offset with respect to the center position.
    % Useful for displaying a picture on the SLM which has a different
    % size than the SLM.
    % - Damien Loterie (01/2014)

    % Parameter checking
    if nargin<3
       offset = zeros(size(size_out)); 
    end
    
    % Pad
    img_out = center_inside(img_in, ...
                            zeros(size_out,'like',img_in),...
                            offset);
end

