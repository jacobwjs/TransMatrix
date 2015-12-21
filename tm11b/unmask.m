function frames = unmask(data, mask)
    % frames = unmask(data, mask)
    % Reconstruct 2D frames from 1D data, using the given mask.
    % This function can also work on multiple frames. In this case, either 
    % each column of data represents a different frame, or data is a single
    % vector containing all the frames one after another.
    %  - Damien Loterie (02/2014)
    
    % Fool proofing
    dims = size(data);
    if numel(dims)>2
       error('Wrong data dimensions'); 
    end
    if sum(dims>1)==1
        number_of_pixels = sum(mask(:));
        number_of_frames = numel(data)/number_of_pixels;
        if (number_of_frames<1 || mod(numel(data),number_of_pixels)~=0)
            error('The mask is incompatible with the size of the data vector.');
        end
    else
        number_of_pixels = size(data,1);
        number_of_frames = size(data,2);
        if (number_of_pixels~=sum(mask(:)))
            error('The mask is incompatible with the size of the data columns.');
        end
    end
    
    % Initialize output frame stack
    frames = zeros([size(mask) number_of_frames], 'like', data);
    
    % Copy data
    frames(repmat(mask,[1 1 number_of_frames])) = data;
    
end

