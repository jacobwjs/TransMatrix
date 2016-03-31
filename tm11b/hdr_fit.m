function [m, q, N, s, M] = hdr_fit(t, y, mask)
    % Calculates a linear regression for every pixel in a stack of frames
    % taken at different exposure levels. You can also define a logical
    % mask to filter out over-exposed and under-exposed pixels.
    % The function returns the parameters m and q such that y = m * t + q.
    % It also returns N, the number of measurement points, s, the standard
    % deviation of the residuals, and M, the maximum deviation.
    %
    %  - Damien Loterie (03/2015)

    % Input processing
    size_y = size(y);
    if numel(size_y)==4
        if size_y(3)==1
            size_y = size_y([1 2 4]);
            y    = reshape(y, size_y);
            mask = reshape(mask, size_y);
        else
            error('Invalid dimensions.'); 
        end
    end
    
    % Create exposure stack
    if numel(t)~=size_y(3)
        error('Invalid dimensions.'); 
    else
        t = reshape(t, [1,1,size_y(3)]);
        t = repmat(t, [size_y(1:2) 1]);
    end

    % Filtering
    if nargin>=3
        t = mask .* t;
        y = mask .* y;
        N = sum(mask,3);
    else
        N = size_y(3);
    end

    % Regression
    m = sum(y.*t, 3) ./ sum(t.^2, 3);
    q = (sum(y, 3)./N) - m.*(sum(t, 3)./N);
    
    % Residual analysis
    if nargout>=4
        % Calculate residuals
        res = y - bsxfun(@plus,bsxfun(@times,m,t),q);
        if nargin>=3
            res = mask.*res;
        end
        
        % Standard deviaton
        s = sqrt(sum(res.^2,3)./(N-2));
        
        % Maximum
        if nargout>=5
           M = max(abs(res),[],3); 
        end
    end
end
