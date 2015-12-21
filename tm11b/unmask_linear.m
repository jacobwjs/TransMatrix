function frames = unmask_linear(data, indices, size_out)
    % frames = unmask_linear(data, indices, size_out)
    % Reconstruct 2D frames from 1D data, using the given mask.
    % This function can also work on multiple frames. In this case, each 
    % column of data must represent a different frame. The indices must be 
    % specified for the first frame only.
    %  - Damien Loterie (03/2014)
    

    % Fool proofing
    dims = size(data);
    if numel(dims)~=2
       error('Wrong data dimensions.'); 
    end
    if sum(size(indices)>1)>1
       error('Masks based on linear indexing must be one-dimensional.');
    end
    if size(indices,2)~=1
       indices = indices.'; 
    end
    number_of_pixels = size(data,1);
    number_of_frames = size(data,2);
    if (number_of_pixels~=numel(indices))
        error('The indices are incompatible with the size of the data columns.');
    end

    % Initialize output frame stack
    frames = zeros([size_out number_of_frames], 'like', data);

    % Calculate indices
    indices = bsxfun(@plus,...
                     indices,...
                     cast((0:(number_of_frames-1))*prod(size_out),'like',indices));
                 
    % Mask the frames
    frames(indices) = data(:);

end

