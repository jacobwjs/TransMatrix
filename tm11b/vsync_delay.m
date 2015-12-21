function delay = vsync_delay(pulse_duration)
    % This functions acts as a global variable for the optimal delay
    % for synchronized triggering.
    % You can also provide a pulse duration, in which case the delay is
    % calculated so as to center the pulse around the optimal time.
    % Measure the delay value using script_vsync_calibration3.m
    %
    %  - Damien Loterie (05/2014)
    
    delay = 15365.5645e-6;
    if nargin>0
       delay = max(20e-9, delay - pulse_duration/2);
    end
end

