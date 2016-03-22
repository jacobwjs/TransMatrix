% Returns a frame from the video object 'vid', based upon settings.
% Derived from 'auto_exposure3.m'.
% - Jacob Staley (02/2016)

% 'vid'      => gigeinput object.
% 'exposure' => exposure time (usecs).
% 'sync'     => boolean: True syncs with SLM, otherwise no synchronization.
function [frame, time] = get_frame(vid, exposure, sync)

if strcmp(get(vid,'TriggerType'),'hardware')
    
    source = get(vid,'source'); 
    % Check camera configuration to ensure hardware triggering and
    % associated settings are in place so the camera can be externally triggered.
    if ~strcmpi(vid.TriggerType,'hardware') ...
            || ~strcmpi(get(source,'FrameStartTriggerMode'), 'On') ...
            || ~strcmpi(get(source,'FrameStartTriggerSource'), 'Line1') ...
            || ~strcmpi(get(source,'ExposureMode'), 'TriggerWidth')
        
        error('Video source is incorrectly configured.');
    end
    
    flushdata(vid);
    vid.TriggerRepeat = Inf;
    
    % Start camera if needed
    if (vid.Running)
        leave_camera_running = true;
    else
        leave_camera_running = false;
        start(vid);
    end
    
    % Get the frame from the camera. 
    if ((exposure < 10) || (exposure > 50e5))
        exposure = 50e3;
        fprintf('Exposure out of bounds: setting to %d\n', exposure);
    end
    trigger_camera(exposure, [], 1, sync);
    pause(0.010);
    [frame, time] = getdata(vid,1);
     
    % Stop camera if it was not running before.
    if ~leave_camera_running
        stop(vid);
    end
    
else
    error('Software triggering of camera currently not supported.');
end



end