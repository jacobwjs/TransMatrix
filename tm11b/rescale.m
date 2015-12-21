function img = rescale(img, q)
    % img = rescale(img, q)
    % Rescale an image between 0 and 1.
    % Additionally, you can specify the quantiles q to use for rescaling.
    %  - Damien Loterie (06/2014)
    
    % Input processing
    img = abs(double(img));
    if nargin<2
        low = min(img(:));
        high = max(img(:));
    else
        lh = quantile(img(:), q(1:2));
        low = lh(1);
        high = lh(2);
    end

    % Output
    img = (img-low)/(high-low);
    img(img>1) = 1;
    img(img<0) = 0;

end

