function [field, phase] = propagate(field, distance, pixel_size, wavelength)
    % field = propagate(field, distance, pixel_size, wavelength)
    % 
    % Propagates a field over a certain distance in free space using
    % a wide-angle FFT-based beam propagation method (BPM).
    %
    %  - Damien Loterie (05/2014)
    
    % Input processing
    narginchk(2,5);
    if nargin<3
        warning('Pixel size not specified. Using the default pixel size.');
        pixel_size = 8e-6 / magnification_factor; 
    else
        if ischar(pixel_size)
            switch pixel_size
                case 'fiber'
                    pixel_size = 8e-6 / magnification_factor; 
                case 'camera'
                    pixel_size = 8e-6;
            end
        end
    end
    if nargin<4
        wavelength = 532e-9;

%         wavelength = 785e-9;
%         warning(['Default wavelength set to ' num2str(wavelength/1e-9) 'nm.']);
    end
    
    % Optical parameters
    k = 2*pi/wavelength;
    
    % Grid parameters
    dx  = pixel_size;
    dy  = pixel_size;
    
    Nx  = size(field,2);
    Ny  = size(field,1);
    
    Lx  = dx*Nx;
    Ly  = dy*Ny;
    
    dkx = 2*pi/Lx;
    dky = 2*pi/Ly;
    
    kx = dkx * fft_axis(Nx);
    ky = dky * fft_axis(Ny);

    % Frequency domain phase grid
    phase_per_distance = sqrt(k^2 - bsxfun(@plus,kx.^2,ky.'.^2));
    distance = reshape(distance,[1 1 numel(distance)]);
    phase_total = bsxfun(@times, phase_per_distance, distance);
    
    % Negative distances: prevent gain and convert to losses instead.
    if (((pi/dx)^2 + (pi/dy)^2) > k^2) && any(distance<0)
       phase_total = real(phase_total) + 1i*abs(imag(phase_total));
    end
    
    % Propagation
    field = ifft2(bsxfun(@times, fft2(field), exp(1i*phase_total)));
    
    % Optional phase
    if nargout>=2
       phase = exp(1i*phase_total);
    end
    
    
end

