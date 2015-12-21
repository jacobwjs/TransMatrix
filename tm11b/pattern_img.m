function img_out = pattern_img(mask_fiber, img, scale_mod, mask_fourier)
    % Function to generate a spot test pattern
    %  - Damien Loterie (02/2014)
    
    % Estimate position of the fiber in the output mask
    [X,Y] = meshgrid(1:size(mask_fiber,2), 1:size(mask_fiber,1));
    x0f = mean(X(mask_fiber));
    y0f = mean(Y(mask_fiber));
    R   = sqrt((X-x0f).^2+(Y-y0f).^2);
    rf  = min(R(bwperim(mask_fiber)));
    
    % Input processing
    if ischar(img)
       img = imread(img); 
    end
    
    % Convert to grayscale
    img = squeeze(mean(double(img),3));
    
    % Crop image
    img_bw = (img~=0);
    img_ch = bwconvhull(img_bw);
    img_p  = bwperim(img_ch);
    
    % Coordinates
    [X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
    P = [X(img_p), Y(img_p)];
    
    % Fit circle
    [x0i, y0i, ri] = mincircle_sqp(P);
    
    % Spline interpolation
    s = csapi({1:size(img,1), ... % y
               1:size(img,2)},... % x
              img);               % data

    % Mapping
    [Xout,Yout] = meshgrid(1:size(mask_fiber,2), 1:size(mask_fiber,1));
    if nargin>=3
        scale = (ri/rf)/scale_mod;
    else
        scale = (ri/rf);
    end
    Xmap = round(scale*Xout + (x0i-scale*x0f));
    Ymap = round(scale*Yout + (y0i-scale*y0f));
    
    % Check which coordinates should be mapped
    mask_map = Xmap>=1 & Xmap<=size(img,2) & Ymap>=1 & Ymap<=size(img,1);
    mask = mask_fiber & mask_map;
    
    % Remap
    img_out = zeros(size(mask_fiber));
    img_out(mask) = fnval(s, [Ymap(mask).'; Xmap(mask).']);
    
    % Fourier
    if nargin>=4
       img_out = ifft2(ifftshift2(fftshift(fft2(img_out)).*mask_fourier)); 
    end
    
end

