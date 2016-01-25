function [reference_mean, reference_std, background_mean, background_std] = ...
           measure_reference(vid, exposure)
	%  - Damien Loterie (05/2014)
       
    % Check camera
    source = vid.source;
    % --------------------------------------- JWJS ----------------
    DeviceID = source.deviceInfo.ID;
    fprintf('Measuring reference for camera: %s (ID=%s)\n',...
            source.name,...
            source.deviceInfo.ID);
%     if ~strcmp(get(source,'DeviceID'), DeviceID)
%         error('This function is designed for the distal-side camera. To use another camera, the shutters must be coded differently.');
%     end 
    % ---------------------------------------------
    
    % Close proximal shutter
    % ---------------------------------------- JWJS ----------
    %shutter('proximal','block');
    %shutter('distal','open');
    display('Block the object path (fiber), and open the reference path ');
    [temp] = input('Press Enter to acquire ');
    % ----------------------------------------------

    % Measure reference beam
    reference_stack = double(getsnapshotse(vid, exposure, 25));
    reference_mean = mean(reference_stack, 4);
    reference_std = std(reference_stack, 0, 4);
    
    % Close distal shutter (which is the reference arm).
    % ---------------------------------------- JWJS ----------
    %shutter('distal','block');
    display('Block both paths (object & reference)');
    [temp] = input('Press Enter to acquire ');
    % ----------------------------------------------

    % Measure reference beam
    background_stack = double(getsnapshotse(vid, exposure, 25));
    background_mean = mean(background_stack, 4);
    background_std = std(background_stack, 0, 4);

    % Reopen shutters
    %shutter('both','pass');
    % ---------------------------------------- JWJS ----------
    display('Open both paths (object & reference)');
    [temp] = input('Press Enter to continue... ');
    % ----------------------------------------------
    
end

