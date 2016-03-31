
% Init SLM
run_test_patterns = false;
slm = slm_device('meadowlark', run_test_patterns);
pause(0.25);
fprintf('\n');

% Anonymous functions for conversion
myfft2  = @(img) fftshift(fft2(ifftshift(img)));
myifft2 = @(img) fftshift(ifft2(ifftshift(img)));
radians_to_8bit = @(img)uint8(mod(angle(img)*256/(2*pi), 256));

% Circular aperture
dims = 512;
radius = 75;
[cc rr] = meshgrid(1:dims);
center_aperture = sqrt((cc-round(dims/2)).^2 + (rr-round(dims/2)).^2) <= radius;
center_left_aperture   = sqrt((cc-round(radius+1)).^2 + (rr-round(dims/2)).^2) <= radius;
center_right_aperture  = sqrt((cc-round(dims-(radius+1))).^2 + (rr-round(dims/2)).^2) <= radius;

bottom_left_aperture = sqrt((cc-round(radius+1)).^2 + (rr-round(dims-(radius+1))).^2) <= radius;
top_left_aperture    = sqrt((cc-round(radius+1)).^2 + (rr-round(radius+1)).^2) <= radius;

slm_imgs = struct();
slm_imgs.mask{1} = center_aperture;
slm_imgs.mask{2} = center_left_aperture;
slm_imgs.mask{3} = center_right_aperture;
slm_imgs.mask{4} = bottom_left_aperture;
slm_imgs.mask{5} = top_left_aperture;


total_mask = uint8(slm_imgs.mask{1});
% total_mask = uint8(slm_imgs.mask{1} + ...
%                     slm_imgs.mask{2} + ...
%                     slm_imgs.mask{3} + ...
%                     slm_imgs.mask{4} + ...
%                     slm_imgs.mask{5});
% total_mask = uint8(slm_imgs.mask{1} + ...
%                   slm_imgs.mask{2} + ...
%                   slm_imgs.mask{5});
%figure, imagesc(total_mask);



% Carrier frequency to align on
DC_offset = 256;
kx = -111;
ky = 111;
carrier = zeros(dims, dims);
carrier(DC_offset + kx,...
        DC_offset + ky) = 1;
carrier = myifft2(carrier);
% Convert to 8-bit representation of phase.
carrier_phase = radians_to_8bit(carrier);

% Cut out aperture with carrier applied.
%masked_carrier_phase = carrier_phase .* uint8(center_aperture);  
% masked_carrier_phase = carrier_phase .* uint8(slm_imgs.mask{3});
masked_carrier_phase = carrier_phase .* total_mask;


% Write to SLM.
slm.Write_img(masked_carrier_phase);
% Display to the user what is written to the SLM.
figure, imagesc(masked_carrier_phase);
drawnow;

%% Alignment of objective to proximal fiber tip
% We want to send in may plane waves to the fiber to fill the NA and excite
% all of the modes the fiber supports. To do this using a TM approach we
% inject many plane waves at many angles. We want to ensure the focus of
% the objective is on the fiber facet such that what is sent into the fiber
% only has an incoming angle shift, not a physical displacement on the
% fiber itself. Therefore we test this here. Alignment is complete when
% there is not a displacement across the fiber facet when each new
% projection angle is written to the SLM.

while 1
    %for i = -20:1:20
        i = 10;
        for j = -80:5:80
            carrier = zeros(dims, dims);
            carrier(DC_offset + kx + i,...
                DC_offset + ky + j) = 1;
            carrier = myifft2(carrier);
            % Convert to 8-bit representation of phase.
            carrier_phase = radians_to_8bit(carrier);
            
            % Cut out aperture with carrier applied.
            %masked_carrier_phase = carrier_phase .* uint8(center_aperture);
            % masked_carrier_phase = carrier_phase .* uint8(slm_imgs.mask{3});
            masked_carrier_phase = carrier_phase .* total_mask;
            
            
            % Write to SLM.
            slm.Write_img(masked_carrier_phase);
            %fprintf('j = %d\n', j);
        end
    %end
end