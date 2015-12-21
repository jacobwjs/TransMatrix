function [basis_function, basis_size, basis_unitary, basis_matrix] = basis_unit(N)
    % Creates a unit basis for TM measurements
	%   - Damien Loterie (02/2014)

    % Data for on-the-fly calculation
    basis_function = @(n)eye_columns(n,N);
    basis_size = [N, N];
    basis_unitary = true;
    
    % Precalculated data
    if nargout>=4
       basis_matrix = eye(N);
    end
    
end

