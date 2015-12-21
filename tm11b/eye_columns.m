function res = eye_columns(cols, N)
    % Gives the selected columns from the identity matrix. Used in the same
    % way as walsh3b, for the selective generation of input vectors in
    % transmission matrix experiments
    %  - Damien Loterie (02/2014)
    
    % Fool proofing
    if any(cols>N) || any(cols<1) || any(cols~=round(cols))
       error('Invalid column indexes'); 
    end
    
    % Initialize array
    res = zeros(N,numel(cols));
    
    % Calculate where the 1's have to go
%     indexes = cols + (0:(numel(cols)-1)) * N;
    indexes = sub2ind([N, N], cols(:), (1:numel(cols)).');
    res(indexes) = 1;
    
end

