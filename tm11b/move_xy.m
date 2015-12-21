function field = move_xy(field, dx, dy)
    % Function to apply a spatial translation to a field.
    % - Damien Loterie (01/2014)

    % Init
    x_img = size(field,2);
    y_img = size(field,1);
       
    % Shift
    [X,Y] = meshgrid(fft_axis(x_img), fft_axis(y_img));
    field = ifft2(fft2(field).*exp(-1i*2*pi*(dx*X/x_img + dy*Y/y_img)));

end

