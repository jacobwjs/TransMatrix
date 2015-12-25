function triggere(DeviceID, ExposureTime, FramesPerSecond, Number, Sync)
    % This is a function to emulate the 'trigger' command from the image
    % acquisition toolbox, except it sends a hardware trigger to the camera
    % via the acquisition card. We had to work this way due to bugs in
    % MATLAB.
    %  - Damien Loterie (02/2014)
      
    % Check the Device ID and find the corresponding digital channel
	%[~,~,CounterName] = camera2name(DeviceID);
    %----------------------------- JWJS --------------
    % No longer hard code the values in 'camera2name', but use the data
    % acquisition toolbox from matlab to find the digital channel.
    % 'DeviceID' is simple a string (i.e. proximal) that maps to a
    % hardcoded value.
    NI_daq = get(daq.getDevices());
    CounterName = strcat(NI_daq(1).ID, '/ctr0');
    
    % Input processing
    narginchk(2,5);
    HighTime = ExposureTime/1e6; % Convert microseconds to seconds
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
    if nargin<5
        Sync = false;
        InitialDelay = [];
    else
        InitialDelay = vsync_delay(HighTime);
    end
    
    % Create counter object
    ctr = DAQmxCounterOutput(CounterName, HighTime, LowTime, InitialDelay);

    % Multiple pulses
    if (Number>1)
        ctr.CfgImplicitTiming('finite', Number);
    end
        
    % Synchronized pulses
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

