function real_order = measure_order_v2(slm, vid, exposure, calibration_frame, camera_to_field)
	%  - Damien Loterie (12/2015)
       
    % Check camera
    source = vid.source;
    DeviceID = source.deviceInfo.ID;
    fprintf('Measuring order for camera: %s (ID=%s)\n',...
            source.name,...
            source.deviceInfo.ID);

    
    % Open shutters
    % FIXME:
    %  - Need to implement something similar for the MARK-1 prototype.
    %shutter('both','open');

    % Show calibration frame
    slm.Write_img(calibration_frame);
    pause(0.100);
    
    % Measure response
    response_original = camera_to_field(double(getsnapshotse(vid, exposure)));
    
    % Show shifted calibration frame
    slm.Write_img(uint8(mod(int32(calibration_frame)+64,256)));
    pause(0.100);

    % Measure reference beam
    response_shifted = camera_to_field(double(getsnapshotse(vid, exposure)));

    % Show calibration frame again
    slm.Write_img(calibration_frame);
    
    % Calculate average measured phase shift
    response_diff = conj(fft2s(response_original)).*fft2s(response_shifted);
    phase_average = sum(sum(abs(response_diff).^2 .* exp(1i*angle(response_diff))));
    phase_average = exp(1i*angle(phase_average));
    
    % Check if this was the right order
    %real_order = abs(phase_average-exp(0.5i*pi)) < abs(phase_average-exp(-0.5i*pi));
	real_order = imag(phase_average)>0;
end

