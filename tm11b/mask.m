function data = mask(frames, mask)
    % data = mask(frames, mask)
    % Create 1D data from 2D images, using the given mask.
    % This function can also work on multiple frames. In this case, the
    % output is a matrix where each column represents one frame.
    %  - Damien Loterie (02/2014)
    
    % Fool proofing
    dims = size(frames);
    if numel(dims)>3 || numel(size(mask))~=2
       error('Wrong frame dimensions.'); 
    end
    if not(all(size(mask)==dims(1:2)))
       error('The mask is incompatible with the frames.'); 
    end
       
    % Initialize output
    data = zeros(sum(mask(:)),size(frames,3), 'like', frames);
    
    % Mask the frames
    data(:) = frames(repmat(mask,[1 1 size(frames,3)]));
    
end

