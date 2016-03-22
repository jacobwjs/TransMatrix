% Generate a series of blazed gratings.

% Meadowlark SLM attributes.
% ---------------------------------------
meadowlark_x_pixels = 512;
meadowlark_y_pixels = 512;


x_pixels = meadowlark_x_pixels;
y_pixels = meadowlark_y_pixels;


% Matches the size of the slm.
k_space_grid = zeros(x_pixels, y_pixels);

% Since the DC term is centered in the k-space grid, we create an offset.
x_center = round(x_pixels/2);
y_center = round(y_pixels/2);

% Fill the grid with ones where we want to create a blazed grating.
k_space_grid(x_center - 75:245, y_center - 1) = 1;

% Find all the locations in the k_space_grid with ones.
[x, y] = find(k_space_grid == 1);

blazed_grating = uint8(zeros(x_pixels, y_pixels));
temp = uint8(zeros(x_pixels, y_pixels));

% Loop and write out all the blazed gratings.
for i = 1:length(x)
    temp(x(i), y(i)) = 1;
    blazed_grating   = angle(fftshift(fft2(ifftshift(temp'))));
    blazed_grating   = mod(blazed_grating, 256);
    imwrite(blazed_grating, ['grating_', ...
                             num2str(x(i)), ...
                             '_', num2str(y(i)), ...
                             '.bmp'], ...
                             'bmp');
    
    % Return the grid to zeros for the next run, otherwise we collect 1's
    % and no longer have a 'blazed' grating.
    temp(x(i), y(i)) = 0;
end
    
