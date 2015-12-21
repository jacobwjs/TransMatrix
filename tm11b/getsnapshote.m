function frame = getsnapshote(vid, exposure_time, sync)
    % Emulates getsnapshot, but with electronic triggering
	%   - Damien Loterie (06/2014)
    
    % Input check
    narginchk(2,3);
    if nargin<2
        error('Not enough input arguments.');
    end
    
    % Check configuration
    source = getselectedsource(vid);
    if ~strcmpi(vid.TriggerType,'hardware') ...
        || ~strcmpi(get(source,'FrameStartTriggerMode'), 'On') ...
        || ~strcmpi(get(source,'FrameStartTriggerSource'), 'Line1') ...
        || ~strcmpi(get(source,'ExposureMode'), 'TriggerWidth')
    
        error('Video source is incorrectly configured.');
    end

    % Clear data
    flushdata(vid);
    
    % Start if needed
    if isrunning(vid)
        leave_camera_running = true;
    else
        leave_camera_running = false;
        start(vid);
    end
    
    % Trigger
    if nargin>=3 && sync==true
        triggere(get(vid.source,'DeviceID'),exposure_time,[],1,true);
    else
        triggere(get(vid.source,'DeviceID'),exposure_time);
    end
    
    % Import frame
    frame = getdata(vid,1);
    
    % Stop
    if ~leave_camera_running
        stop(vid);
    end

end

