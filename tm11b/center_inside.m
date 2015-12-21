function target = center_inside(source, target, offset)
    % Places the source image inside the target image, at its center.
    % Also allows for an offset with respect to that center position.
    % - Damien Loterie (01/2014)
    
    % Parameter checking
    size_in = size(source);
    size_out = size(target);
    if numel(size_in)~=numel(size_out)
        error('Dimension mismatch between source and target.');
    end
    if nargin<3
        offset = zeros(size(size_in));
    else
        if numel(size_in)~=numel(offset)
            error('Dimension mismatch between data and offset.');
        end
    end
    
    % Calculate mapping
    map_in = cell(numel(size_in),1);
    map_out = cell(numel(size_out),1);
    for i = 1:numel(size_in)
        % Initial values
        length_of_copy = size_in(i);
        difference     = floor((size_out(i)+1)/2) - floor((size_in(i)+1)/2);
        start_target   = 1 + difference + round(offset(i));
        start_source   = 1;
        
        % Correct for clipping
        if (start_target<1)
            start_source   = start_source   - (start_target - 1);
            length_of_copy = length_of_copy + (start_target - 1);
            start_target   = 1;
        end
        if ((start_source+length_of_copy-1)>size_in(i))
            length_of_copy = size_in(i) - start_source + 1;
        end
        if ((start_target+length_of_copy-1)>size_out(i))
            length_of_copy = size_out(i) - start_target + 1;
        end
        
        % Calculate indices
        map_in{i}  = start_source + (0:(length_of_copy-1));
        map_out{i} = start_target + (0:(length_of_copy-1));
    end
    
    % Execute
    target(map_out{:}) = source(map_in{:});
    
end

