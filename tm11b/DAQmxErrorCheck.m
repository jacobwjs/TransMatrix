function DAQmxErrorCheck(ExitCode, Warning)
    % Script to check the error codes returned by the ni DAQmx library
    %  - Damien Loterie (02/2014)
    
    
    % If there's no error, leave now.
    if (ExitCode==0)
        return;
    end
    
    % Get error length
    [BufferSize, ~] = calllib('NIDAQmx', 'DAQmxGetErrorString', ExitCode, libpointer, 0);
    if (BufferSize<=0)
       error(['DAQmx unexpected error (code ' num2str(ExitCode) ')']);
    end
    
    % Get error string
    ErrorString = repmat(' ',BufferSize,1);
    [Status, ErrorString] = calllib('NIDAQmx', 'DAQmxGetErrorString', ExitCode, ErrorString, BufferSize);
    if (Status~=0)
       error(['DAQmx unexpected error (code ' num2str(ExitCode) ')']);
    end
    
    % Check code
    if ExitCode>0
        warning(['DAQmx warning ' num2str(ExitCode) ': ' ErrorString]);
    elseif ExitCode<0
        if nargin>1 && strcmp(Warning,'warning')
            warning(['DAQmx error ' num2str(ExitCode) ': ' ErrorString]);
        else
            error(['DAQmx error ' num2str(ExitCode) ': ' ErrorString]);
        end
    end

end

