function data = mask_linear(frames, indices)
    % data = mask(frames, mask, matrix_output)
    % Create 1D data from 2D images, using the given mask.
    % If multiple frames are passed, the output is a matrix where each
    % column contains the masked data for one frame.
    %  - Damien Loterie (03/2014)
    
    % Fool proofing
    dims = size(frames);
    switch numel(dims)
        case 3
            number_of_frames = dims(3);
        case 2
            number_of_frames = 1;
        otherwise  
            error('Wrong frame dimensions.'); 
    end
    if sum(size(indices)>1)>1
       error('Masks based on linear indexing must be one-dimensional.');
    end
    if size(indices,2)~=1
       indices = indices.'; 
    end
       
    % Calculate indices
    indices = bsxfun(@plus,...
                     indices,...
                     (zeros(1,1,class(indices)):(number_of_frames-1))*(dims(1)*dims(2)));
                 
    % Mask the frames
    data = frames(indices);

end

