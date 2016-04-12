function DAQmxGetExtendedErrorInfo()
	%   - Damien Loterie (02/2014)
    
    % Get error length
    [BufferSize, ~] = calllib('NIDAQmx', 'DAQmxGetExtendedErrorInfo', libpointer, 0);
    if (BufferSize<=0)
       error('DAQmxGetExtendedErrorInfo unexpected error');
    end
    
    % Get error string
    ErrorString = repmat(' ',BufferSize,1);
    [Status, ErrorString] = calllib('NIDAQmx', 'DAQmxGetExtendedErrorInfo', ErrorString, BufferSize);
    if (Status~=0)
       error('DAQmxGetExtendedErrorInfo unexpected error');
    end
    
    % Display
    disp('[Extended error information]');
    disp(ErrorString);

end

