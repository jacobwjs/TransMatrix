function [reference_mean, reference_std, background_mean, background_std] = ...
           measure_reference(vid, exposure)
	%  - Damien Loterie (05/2014)
       
    % Check camera
    source = vid.source;
    [~, DeviceID] = camera2name('distal');
    if ~strcmp(get(source,'DeviceID'), DeviceID)
        error('This function is designed for the distal-side camera. To use another camera, the shutters must be coded differently.');
    end 
    
    % Close proximal shutter
    shutter('proximal','block');
    shutter('distal','open');

    % Measure reference beam
    reference_stack = double(getsnapshotse(vid, exposure, 25));
    reference_mean = mean(reference_stack, 4);
    reference_std = std(reference_stack, 0, 4);
    
    % Close distal shutter
    shutter('distal','block');

    % Measure reference beam
    background_stack = double(getsnapshotse(vid, exposure, 25));
    background_mean = mean(background_stack, 4);
    background_std = std(background_stack, 0, 4);

    % Reopen shutters
    shutter('both','pass');
    
end

