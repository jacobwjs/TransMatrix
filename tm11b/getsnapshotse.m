function frames = getsnapshotse(vid, exposure, n, sync)
    %GETSNAPSHOTSE Get multiple snapshots in a row with electronic triggers
    % - Damien Loterie (04/2014)
    
    % Input processing
    narginchk(1,4);
    source = vid.source;
    if ~strcmpi(vid.TriggerType,'hardware') ...
        || ~strcmpi(get(source,'FrameStartTriggerMode'), 'On') ...
        || ~strcmpi(get(source,'FrameStartTriggerSource'), 'Line1') ...
        || ~strcmpi(get(source,'ExposureMode'), 'TriggerWidth') ...
        || ~isinf(vid.TriggerRepeat)
        error('Video source is incorrectly configured.');
    end  
    if ~strcmpi(get(source,'ExposureMode'), 'TriggerWidth')
       warning('Video source is not set to TriggerWidth exposure mode'); 
    end
    if nargin<2
        exposure = [];
    end
    if numel(exposure)>1 
        if (nargin<3 || isempty(n) || n==numel(exposure))
            n = numel(exposure);
        else
            error('If the number of frames is specified, the exposure time must be a single value and not and array.');
        end
    elseif numel(exposure)==1
        if nargin<3 || isempty(n)
            n = 1;
        else
            if numel(n)~=1 || ~isnumeric(n) || ~(n==round(n))
               error('Invalid number of frames'); 
            end
            exposure = repmat(exposure,1,n);
        end
    else % numel(exposure)==0
        if strcmpi(get(source,'ExposureMode'), 'TriggerWidth')
            error('In TriggerWidth mode, you must specify an exposure time.');
        else
            if nargin<2 || isempty(exposure)
                exposure = 500;
            end
            if nargin<3 || isempty(n)
                n = 1;
            end
        end
    end
    if nargin>3
       if ~islogical(sync) || numel(sync)~=1
          error('Synchronization must be specified with a single logical value'); 
       end
    else
       sync = false; 
    end
    
    % Configure pulses
	[~,~,CounterName] = camera2name(get(source,'DeviceID'));
    HighTimes = exposure/1e6;
    ctr = DAQmxCounterOutput(CounterName, ...
                             HighTimes(1), ...
                             [], ...
                             vsync_delay(HighTimes(1)));
    if (sync)
        ctr.CfgDigEdgeStartTrig(vsync_channel, 'falling');
    end

    % Start camera
    flushdata(vid);
    start(vid);
    
    % Send pulses and record frames
    frames = [];
    for i=1:n
        ctr.HighTime     = HighTimes(i);
        ctr.InitialDelay = vsync_delay(HighTimes(i));
        ctr.start();
        if isempty(frames)
            frames = getdata(vid,1);
            if n>1
                frames(:,:,:,n) = 0;
            end
        else
            frames(:,:,:,i) = getdata(vid,1); %#ok<AGROW>
        end
        ctr.stop();
    end
    
    % Stop
    ctr.delete;
    stop(vid);
    flushdata(vid);
end

