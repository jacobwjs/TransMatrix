% Settings
lambda = 785e-9

% Holoeye SLM attributes.
% -----------------------------------------
holoeye_x_pixels    = 1920;
holoeye_y_pixels    = 1080;
holoeye_pixel_size  = 8e-6;

% Meadowlark SLM attributes.
% -----------------------------------------
meadowlark_x_pixels = 512;
meadowlark_y_pixels = 512;
meadowlark_pixel_size = 15e-6;

% Camera attributues.
% -----------------------------------------
% Andor camera: 1002x1004
x_pixels_camera     = 1024;
y_pixels_camera     = 1024;
pixel_size_camera   = 8e-6;

Nx = x_pixels_camera;
Ny = y_pixels_camera;
dx = 8e-6;
dy = dx;

% Physical size of the camera sensor.
% -----------------------------------------
x_ = [-.5*Nx:.5*Nx-1]*dx;
y_ = [-.5*Ny:.5*Ny-1]*dy;
[Y_ X_] = meshgrid(y_,x_);


x = [-.5*Nx:.5*Nx-1];
y = [-.5*Ny:.5*Ny-1];
[Y X] = meshgrid(y,x);

dxc = 0.3519e-6;
dyc = 0.3519e-6;
xc = [-.5*Nx:.5*Nx-1]*dxc;
yc = [-.5*Ny:.5*Ny-1]*dyc;
[Yc Xc] = meshgrid(yc,xc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load holograms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open the object image and get the path to the file.
[object_file, path_ref] = uigetfile('*.bmp', 'Open the REFERENCE image file');
if object_file == 0, return, end
object_file  = strcat(path_ref, object_file);
object_image = imread(object_file);


% Open the reference image and get the path to the file.
[reference_file, path_ref] = uigetfile('*.bmp', 'Open the OBJECT image file');
if reference_file == 0, return, end
reference_file  = strcat(path_ref, reference_file);
reference_image = imread(reference_file);

% Open the hologram image and get the path to the file.
[hologram_file, path_holo] = uigetfile('*.bmp', 'Open the HOLOGRAM image file');
if hologram_file == 0, return, end
hologram_file   = strcat(path_holo, hologram_file);
hologram_image  = imread(hologram_file);

% Open the dark frame image and get the path to the file.
[dark_frame_file, path_dark_frame] = uigetfile('*.bmp', 'Open the DARK FRAME image file');
if dark_frame_file == 0, return, end
dark_frame_file     = strcat(path_dark_frame, dark_frame_file);
dark_frame          = imread(dark_frame_file);

% Remove camera noise from the images.
object_image    = object_image - dark_frame;
hologram_image  = hologram_image - dark_frame;
reference_image = reference_image - dark_frame;




%%%%%%%% SQUARE WINDOW %%%%%%%%%%%%%%%%%%%%
sw_x = x_pixels_camera;              % side_window x direction  [pixels]
sw_y = y_pixels_camera;              % side_window y direction  [pixels]
M_0 = length(hologram_image(:,1));     % initial number of rows
N_0 = length(hologram_image(1,:));     % initial number of columns
    
C_m = fix(M_0/2);         % central window position - x
C_n = fix(N_0/2);         % central window position - y
    
object    = object_image(C_m+1-fix(sw_x/2):C_m+fix(sw_x/2),... 
                           C_n+1-fix(sw_y/2):C_n+fix(sw_y/2));
hologram  = hologram_image(C_m+1-fix(sw_x/2):C_m+fix(sw_x/2),... 
                           C_n+1-fix(sw_y/2):C_n+fix(sw_y/2));
reference = reference_image(C_m+1-fix(sw_x/2):C_m+fix(sw_x/2),...
                            C_n+1-fix(sw_y/2):C_n+fix(sw_y/2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Remove intensity contribution of reference from the
% hologram, and then remove the object, leaving fringes. 
% ------------------------------------------------------
fringes = hologram - reference;
fringes = fringes - object;



% Select a the center of the +1 order in k-space to define the carrier
% frequency and filter out the -1 order and DC terms.
% -------------------------------------------------------
%normalized_holo = mat2gray(hologram - reference);
normalized_holo = fringes;
FFT_normalized_holo = fftshift(fft2(ifftshift(normalized_holo)));
figure, imagesc(db(abs(FFT_normalized_holo)));
display('click center of +1 order');
[x,y] = ginput(1);
first_order = [];
first_order.center_x = fix(x);
first_order.center_y = fix(y);

%
delta_carrier = zeros(Nx,Ny)';
%delta_carrier(y0_hol,x0_hol) = 1;
delta_carrier(first_order.center_y, first_order.center_x) = 1;
carrier = fftshift(fft2(ifftshift(delta_carrier)));

display('click left and right edges of +1 order');
[waist_leftside_x, waist_leftside_y]    = ginput(1);
[waist_rightside_x, waist_rightside_y]  = ginput(1);
first_order.leftside_x  = fix(waist_leftside_x);
first_order.rightside_x = fix(waist_rightside_x);
first_order.leftside_y  = fix(waist_leftside_y);
first_order.rightside_y = fix(waist_rightside_x);

%waist_hol = 0.16*Nx;%*pixel_size_CMOS*x_pixels_CMOS; %0.05*taille du sensor
waist_hol = fix(abs(first_order.leftside_x - first_order.rightside_x)/2);
%spectral_filter = (exp(-(((X-(x0_hol-0.5*Nx)).^2+(Y-(y0_hol-0.5*Nx)).^2)/waist_hol^2).^15)).';
spectral_filter2 = (exp(-(((X-(first_order.center_x - 0.5*Nx)).^2 ...
                         + (Y-(first_order.center_y - 0.5*Ny)).^2) ...
                           /waist_hol^2).^10)).';


holo = normalized_holo;                                     % hologram
FFT_holo = fftshift(fft2(ifftshift(holo)));                 % hologram Fourier Transform
FFT_holo_masked = FFT_holo.*spectral_filter2;               % hologram Fourier Transform masked
field_recon = fftshift(ifft2(ifftshift(FFT_holo_masked)));  % Reconstructed field 


% FT_holo = fftshift(fft2(ifftshift(holo)));              % hologram Fourier Transform
% FT_holo_masked = ifftshift(FT_holo.*spectral_filter);   % hologram Fourier Transform masked
% field_recon = ifftshift(ifft2(FT_holo_masked));         % Reconstructed field 

figure, imagesc(db(abs(FFT_holo))), axis image, colormap(jet), title('hologram FFT')
figure, imagesc(abs(FFT_holo_masked)), axis image, colormap(jet), title('hologram FFT masked')
figure, imagesc(abs(field_recon)), axis image, colormap(jet), title('reconstructed field: AMPLITUDE')
figure, imagesc(angle(field_recon)), axis image, colormap(jet), title('reconstructed field: PHASE + carrier')
figure, imagesc(angle(field_recon.*(carrier))), axis image, colormap(jet), title('reconstructed field: PHASE')
figure, imagesc(abs(FFT_holo_masked)), axis image, colormap(jet), title('hologram FFT masked')



