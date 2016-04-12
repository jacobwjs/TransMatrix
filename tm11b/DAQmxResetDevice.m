function DAQmxResetDevice(device_name)
	%   - Damien Loterie (05/2015)
    
	% Check that the DAQmx library is loaded
	DAQmxLoadLibrary();
	
	% Reset device
	[ExitCode, ~] = calllib('NIDAQmx', ...
							'DAQmxResetDevice', ...
							[device_name,0]);
													   
	% Check errors
	DAQmxErrorCheck(ExitCode);

end
