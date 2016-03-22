

% Anonymous functions for conversion
myfft2  = @(img) fftshift(fft2(ifftshift(img)));
myifft2 = @(img) fftshift(ifft2(ifftshift(img)));
radians_to_8bit = @(img)uint8(mod(angle(img)*256/(2*pi), 256));


% Initialize the SLM
sdk = Initialize_meadowlark_slm(false);


% Circular aperture
dims = 512;
radius = 25;
[cc rr] = meshgrid(1:dims);
center_aperture = sqrt((cc-round(dims/2)).^2 + (rr-round(dims/2)).^2) <= radius;
center_aperture = uint8(center_aperture);

% Carrier frequency to align on
DC_offset = 256;
kx = -100;
ky = 100;
carrier1 = zeros(dims, dims);
carrier1(DC_offset + kx,...
        DC_offset + ky) = 1;
carrier1 = myifft2(carrier1);
% Convert to 8-bit representation of phase.
frame1 = radians_to_8bit(carrier1) .* center_aperture;


carrier2 = zeros(dims, dims);
carrier2(DC_offset + kx+5,...
        DC_offset + ky+5) = 1;
carrier2 = myifft2(carrier2);
% Convert to 8-bit representation of phase.
frame2 = radians_to_8bit(carrier2) .* center_aperture;

frame_blank = 255*ones(512, 512);
calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, frame_blank, 0, 1);


while 1
    calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, frame1, 0, 1);
    calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, frame2, 0, 1);
end

cnt = 0;
cnt = uint8(cnt);
t_frames = uint8(zeros(512, 512, 20));
calllib('Blink_SDK_C', 'Calculate_transient_frames', sdk, frame1, uint8(512*512));
calllib('Blink_SDK_C', 'Retrieve_transient_frames', sdk, t_frames);


% calllib('Blink_SDK_C', 'Write_overdrive_image', sdk, 1, frame1, 0, 1);
% calllib('Blink_SDK_C', 'Calculate_transient_frames', sdk, frame1, 0);
% calllib('Blink_SDK_C', 'Is_slm_transient_constructed', sdk)


