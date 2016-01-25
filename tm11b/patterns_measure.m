function [experiments, speckle_ref] = patterns_measure(vid, ...
                                                       d, ...
                                                       camera_to_output, ...
                                                       camera_to_field, ...
                                                       experiments, ...
                                                       speckle_frame)

    % Measure the response to the specified input patterns
    % - Damien Loterie (02/2014; updated 04/2014)
          

    % Reconfigure system
    %shutter('both','pass');
    
    d.setConfig('pulseEnable', false);
    
    set(vid.source,'ExposureMode','TriggerWidth');
    set(vid, 'TriggerRepeat', Inf);
    
    start(vid);

    % Display test masks and record holograms
    h_fig = figure;
    for i=1:numel(experiments)
        % Show on SLM
        d.show(experiments(i).SLM);
        pause(0.100);

        % Auto-exposure
        flushdata(vid);
        [exposure_value, frame] = auto_exposure3(vid);

        % Save hologram and reconstruction
        experiments(i).Hologram = frame;
        experiments(i).HologramExposure = exposure_value;
        experiments(i).Y_meas = camera_to_output(frame);

        % Show image
        figure(h_fig);
        imagesc(abs(camera_to_field(frame)));
        axis image; axis off;
        title({['Experiment #' num2str(i)], ...
               'Output field amplitude'});
    end
    
    
    % Record intensities
    % ---------------------------------------- JWJS ----------
    %shutter('distal','block');
    display('Block reference path');
    [temp] = input('Press Enter to acquire \n');
    % ----------------------------------------------
    
    disp('Recording intensities...');
    for i=1:numel(experiments)
        % Show on SLM
        d.show(experiments(i).SLM);
        pause(0.100);

        % Auto-exposure
        flushdata(vid);
        [exposure_value, frame] = auto_exposure3(vid);

        % Save frame
        experiments(i).I_out = frame;
        experiments(i).I_exposure = exposure_value;

        % Show image
        figure(h_fig);
        imagesc(experiments(i).I_out);  colormap gray;
        axis image; axis off;
        title({['Experiment #' num2str(i)], ...
               'Output field amplitude'});
    end

    % Record a calibration (speckle) shot
    disp('Recording calibration image...');
    d.show(speckle_frame);
    pause(0.100);
    [exposure_value, frame] = auto_exposure3(vid);
    
    speckle_ref = struct();
    speckle_ref.I_out = frame;
    speckle_ref.I_exposure = exposure_value;
    
    % Record background images with the same exposure levels (fixed pattern noise)
    % --------------------------------------------- JWJS ---------
    %shutter('both','block');
    display('Block reference and object paths');
    [temp] = input('Press Enter to acquire \n');
    % ----------------------------------------------
    disp('Recording background...');
    for i=1:numel(experiments)
        experiments(i).I_bg = getsnapshote(vid, experiments(i).I_exposure);
        pause(0.100);
    end
    speckle_ref.I_bg = getsnapshote(vid, speckle_ref.I_exposure);
    
    % Stop camera
    stop(vid);
    
    % Open shutters again
    % --------------------------------------------- JWJS ---------
    %shutter('both','open');
    display('Open both reference and object paths');
    [temp] = input('Press Enter to continue \n');
    % ----------------------------------------------
end

