% Function is used to propagate an output a given distance based on various
% attributes (i.e. wavelength, pixel_size, magnification of imaging system
% from fiber to camera, etc.).
% Nico Stasio, Jacob Staley (March 2016)
%
% NOTE:
% - This function only computes the fields based on an input. To form the
%   phase mask for the SLM you would need to do the following,
%        Y_target = field_to_output(field);
%        X_inv = inversions.T_inv * Y_target;
%        SLM_mask = uint8(input_to_slm(X_inv));
%
%
% Given small enough pixel size, a way to test the NA of the fiber.
% Nico Stasio (March, 2016)
% % -----------------------------------------------------
% [X Y] = meshgrid(x_,y_);
% % Frequency domain phase grid
%
% NA_exc = 0.4;
% omega_exc = 2*pi*NA_exc/wavelength;
% R = sqrt(X.^2 + Y.^2);
% PSF_exc = 1*2*((besselj(1,(omega_exc*R)))./(omega_exc*R));
% PSF_exc(.5*Nx+1, .5*Nx+1) = 1;



function [propagated_fields] = propagate_v2(output_to_propagate,...
                                                          distance_vals,...
                                                          pixel_size,...
                                                          wavelength,...
                                                          magnification_vals)

DEBUG = false;



Nx = size(output_to_propagate, 1);
Ny = size(output_to_propagate, 2);

% Allocate a 3D matrix that contains the SLM phase masks for the
% magnification(s) and distance(s). 
% NOTE:
% - Magnification will only change when the imaging system to form the spot
%   on the camera is translated.
propagated_fields = zeros(Nx, Ny, length(distance_vals)*length(magnification_vals));
                                          


%scan_range = 21.85%:0.05:22.85;

% Used as an index to store the computed fields in 3D matrix.
counter = 0;

% In case a vector of magnifications is passed in, we loop and produce
% outputs for each distance.
for magnification_factor = magnification_vals
    
    if (DEBUG)
            magnification_factor
    end
    
    for distance = distance_vals
        counter = counter + 1;
      
        % Wave number
        k = 2*pi/wavelength;
        
        % Grid parameters
        dx  = 8e-6/magnification_factor;
        dy  = 8e-6/magnification_factor;
        
        Lx  = dx*Nx;
        Ly  = dy*Ny;
        
        dkx = 2*pi/Lx;
        dky = 2*pi/Ly;
        
        
        kx = dkx * fft_axis(Nx);
        ky = dky * fft_axis(Ny);
        
        [Kx Ky] = meshgrid(kx,ky);
        
       
        propagated_fields(:,:,counter) = ifft2(fft2(output_to_propagate).*exp(1i.*(Kx.^2 + Ky.^2)*-1*distance/2/k));
       
        if (DEBUG)
            figure, imagesc(angle(propagated_fields(:,:,counter)));
        end   
        
    end
end
