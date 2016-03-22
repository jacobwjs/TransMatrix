function trigger_camera(ExposureTime, FramesPerSecond, Number, Sync)
% This is a function to emulate the 'trigger' command from the image
% acquisition toolbox, except it sends a hardware trigger to the camera
% via the acquisition card. We had to work this way due to bugs in
% MATLAB.
%  - Damien Loterie (02/2014)

% Removing unnecessary functionality and cleaning up code. Derived from
% 'triggere.m'.

% Get the DAQ specific values.
NI_daq = get(daq.getDevices());
CounterName = strcat(NI_daq(1).ID, '/ctr0');

% Input processing
narginchk(1,4);

% Convert microseconds to seconds.
HighTime = ExposureTime/1e6; 

% If 'Number' was not specified, set default values.
if nargin<4
    Number = 1;
    LowTime = [];
else
    Number = max(1,round(Number));
    if Number>1
        Period = 1/FramesPerSecond;
        if Period<=(HighTime+1e-6)
            error('Period too fast compared to the pulse width');
        end
        if (Period*Number)>1800
            warning('Measurement too long?');
        end
        LowTime = Period-HighTime;
    else
        LowTime = [];
    end
end

if (Sync)
    % FIXME:
    %  - Does this need updating for the Meadowlark SLM?
    InitialDelay = vsync_delay(HighTime);
else
    InitialDelay = [];
end

% Create counter object
ctr = DAQmxCounterOutput(CounterName, HighTime, LowTime, InitialDelay);

% Multiple pulses
if (Number>1)
    ctr.CfgImplicitTiming('finite', Number);
end

% Synchronized pulses based on the SLM output trigger (i.e. the SLM is
% refreshed).
if (Sync)
    ctr.CfgDigEdgeStartTrig(vsync_channel, 'falling');
end

% Generate
ctr.start();

% Wait
WaitTime = 5;
if Number>1
    WaitTime = WaitTime + Number/FramesPerSecond;
end
ctr.wait(WaitTime);

end


