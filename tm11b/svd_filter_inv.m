function s_inv = svd_filter_inv(s, type, parameter)
    % s_inv = svd_filter_inv(s, type, parameter)
    %
    % Returns the filtered inverse of the singular values s.
    % Useful for TSVD or Tikhonov regularized inverses.
    % The knee point parameter lambda = max(s)*lambda_relative.
    %
    %  - Damien Loterie (05/2014)
    
    switch lower(type)
        case 'tikhonov'
            lambda = max(s)*parameter;
            s_inv = s ./ (s.^2 + lambda^2);
        case 'tikhonov by index'
            lambda = s(min(numel(s),parameter));
            s_inv = s ./ (s.^2 + lambda^2);
        case 'truncated'
            select = s>(max(s)*parameter);
            s_inv = zeros(size(s));
            s_inv(select) = 1./s(select);
        case 'truncated by index'
            select = 1:min(numel(s),parameter);
            s_inv = zeros(size(s));
            s_inv(select) = 1./s(select);
        case 'truncated2 by index'
            select = 1:min(numel(s),parameter);
            s_inv = zeros(size(s));
            s_inv(select) = 1./s(select).^2;
        otherwise
            error('Unrecognized filter type');
    end


end

