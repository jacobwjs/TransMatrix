function [A,varargout] = minnd(A, dims)
    % [c, i, j, ...] = minnd(A, dims)
    % Generalization of the min function, which calculates the minimum
    % over many dimensions at the same time. The function also returns
    % the indices of the minima for the specified dimensions.
    %  - Damien Loterie (10/2014)


    % Prepare output
    varargout = cell(numel(dims),1);
    
    % Run algorithm
    for i=1:numel(dims)
        [A, varargout{i}] = min(A,[],dims(i));
        for j=1:(i-1)
            ind = varargout{j};
            varargout{j} = ind(varargout{i});
        end
    end
end

