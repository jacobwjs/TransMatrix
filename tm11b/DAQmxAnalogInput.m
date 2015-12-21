classdef DAQmxAnalogInput < DAQmxChannel
    % DAQmxAnalogInput: Interface to analog input functions
    %                     in the NI DAQmx C library.
    %
    % Allows to use advanced features of the NI DAQmx analog inputs.
    % Refer to the NI X-series manual for more information about the 
    % implemented functions.
    %
    % Note: As of March 2015, not all of the DAQmx library functions are
    %       implemented (only the ones I needed). To implement new
    %       functions, read the NI-DAQmx C Reference manual and follow the
    %       same patterns as in the already implemented methods.
    %       Also, I only implemented the voltage measurement, because this
    %       is the only thing the PCIe6232 can do. Many other analog input
    %       types are available.
    %
    %  - Damien Loterie (04/2015)
    
    %%%%%%%%%%%%%%%
    % CONSTRUCTOR %
    %%%%%%%%%%%%%%%
    properties (SetAccess=private, GetAccess=public)
       PhysicalChannel; 
    end
    
    methods
        function obj = DAQmxAnalogInput(PhysicalChannel, ...
                                        TerminalConfig,...
                                        MinVoltage, ...
                                        MaxVoltage)                   
            % Input processing
            narginchk(4,4);
            if isempty(TerminalConfig)
                TerminalConfig = DAQmxAnalogInput.DAQmx_Val_Cfg_Default;
            else
                TerminalConfig = DAQmxAnalogInput.TerminalConfig_str2code(TerminalConfig);
            end
            
            % Range check
            if     MinVoltage<DAQmxAnalogInput.VoltageMin ...
            	|| MinVoltage>DAQmxAnalogInput.VoltageMax ...
            	|| MaxVoltage<DAQmxAnalogInput.VoltageMin ...
            	|| MaxVoltage>DAQmxAnalogInput.VoltageMax ...
                || MinVoltage>MaxVoltage
                 error(['The voltage values must be in the range [' ...
                        num2str(DAQmxAnalogInput.VoltageMin) ...
                        '; ' ...
                        num2str(DAQmxAnalogInput.VoltageMax) ...
                        '], and MinVoltage < MaxVoltage.']);
            end
                                      
            % Call superclass constructor
            obj = obj@DAQmxChannel;
            
            % Create channel
            obj.PhysicalChannel = PhysicalChannel;
            ExitCode = calllib('NIDAQmx','DAQmxCreateAIVoltageChan', ...  
                                         obj.TaskHandle, ...        % Task handle
                                         [obj.PhysicalChannel,0], ...   % Device/Channel
                                         '', ...                    % Channel name
                                         TerminalConfig, ...        % Terminal configuration
                                         MinVoltage, ...            % Minimum of the voltage range
                                         MaxVoltage, ...            % Maximum of the voltage range
                                         DAQmxAnalogInput.DAQmx_Val_Volts, ... % Voltage units
                                         '');                 % Custom voltage scale name
            if (ExitCode<0)
                disp(['MinVoltage:' num2str(MinVoltage)]);
                disp(['MaxVoltage:' num2str(MaxVoltage)]);
            end
                                                
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    end
    
    %%%%%%%%%%%
    % METHODS %
    %%%%%%%%%%%
    methods
        function readArray = getdata(obj, n, timeout)
            % Input checking
            if nargin<2 || isempty(n)
               n = 1;
            else
                if ~isnumeric(n) || ~isreal(n) || n<1 || n~=round(n)
                   error('Invalid number of samples');
                end
                n = int32(n);
            end
            if nargin<3 || isempty(timeout)
               timeout = 10;
            else
                if timeout==-1
                    timeout = DAQmxChannel.DAQmx_Val_WaitInfinitely;
                elseif ~isnumeric(timeout) || ~isreal(timeout) || timeout<0
                   error('Invalid timeout');
                end
                timeout = double(timeout);
            end
            
            % Library call
            [ExitCode, ~ , readArray, samplesRead] ...
                    = calllib('NIDAQmx','DAQmxReadAnalogF64', ...  
                                         obj.TaskHandle, ...        % Task handle
                                         int32(n), ...              % Number of samples per channel
                                         double(timeout), ...       % Timeout
                                         DAQmxChannel.DAQmx_Val_GroupByScanNumber, ... % Fill mode
                                         zeros(n,1), ...            % Output array
                                         uint32(n), ...             % Size of the output array
                                         int32(0), ...              % Samples read
                                         libpointer);               % Reserved

            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Check number of samples
            if ~(n==samplesRead && samplesRead==numel(readArray))
               error('Unexpected number of output samples.'); 
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%
    % DAQmx PROPERTIES %
    %%%%%%%%%%%%%%%%%%%%
    properties (Dependent, SetAccess=public, GetAccess=public)
        TerminalConfig;
        MinVoltage;
        MaxVoltage;
    end
    methods 
        % TerminalConfig
        function res = get.TerminalConfig(obj)
            % Get StartTriggerType
            [ExitCode, ~, ~, code] = calllib('NIDAQmx', ...
                                             'DAQmxGetAITermCfg', ...
                                             obj.TaskHandle, ...
                                             obj.PhysicalChannel,...
                                             int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxAnalogInput.TerminalConfig_code2str(code);
        end
        function set.TerminalConfig(obj, cfg)
            % Translate value
            code = DAQmxAnalogInput.TerminalConfig_str2code(cfg);
            
            % Set TerminalConfig
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxGetAITermCfg', ...
                                    obj.TaskHandle, ...
                                    [obj.PhysicalChannel,0],...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % MaxVoltage
        function res = get.MaxVoltage(obj)
            % Get MaxVoltage
            [ExitCode, ~, ~, res] = calllib('NIDAQmx', ...
                                            'DAQmxGetAIMax', ...
                                            obj.TaskHandle, ...
                                            [obj.PhysicalChannel,0],...
                                            double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.MaxVoltage(obj, value)
            % Set MaxVoltage
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetAIMax', ...
                                    obj.TaskHandle, ...
                                    [obj.PhysicalChannel,0],...
                                    value);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % MinVoltage
        function res = get.MinVoltage(obj)
            % Get MinVoltage
            [ExitCode, ~, ~, res] = calllib('NIDAQmx', ...
                                            'DAQmxGetAIMin', ...
                                            obj.TaskHandle, ...
                                            [obj.PhysicalChannel,0],...
                                            double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.MinVoltage(obj, value)
            % Set MinVoltage
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetAIMin', ...
                                    obj.TaskHandle, ...
                                    [obj.PhysicalChannel,0],...
                                    value);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    end
    
    
    %%%%%%%%%%%%%
    % CONSTANTS %
    %%%%%%%%%%%%%
    properties (Constant, Access=private)
        % Analog input limit values
        % Note: The values below are hardcoded for my NI PCIe-6323.
        %       You may have to change them for other cards.
        VoltageMin = -10;
        VoltageMax = 10;
        
        % Input units
        DAQmx_Val_Volts         = int32(10348);

        % Terminal configurations
        DAQmx_Val_Cfg_Default   = int32(-1);
        DAQmx_Val_RSE           = int32(10083);
        DAQmx_Val_NRSE          = int32(10078);
        DAQmx_Val_Diff          = int32(10106);
        DAQmx_Val_PseudoDiff    = int32(12529);
        
    end
    
    methods (Static, Access=private)
        % TerminalConfig translations
        function res = TerminalConfig_str2code(state)
            switch lower(state)
                case 'default'
                    res = DAQmxAnalogInput.DAQmx_Val_Cfg_Default;
                case 'rse'
                    res = DAQmxAnalogInput.DAQmx_Val_RSE;
                case 'nrse'
                    res = DAQmxAnalogInput.DAQmx_Val_NRSE;
                case 'diff'
                    res = DAQmxAnalogInput.DAQmx_Val_Diff;
                case 'pseudodiff'
                    res = DAQmxAnalogInput.DAQmx_Val_PseudoDiff;
                otherwise
                    error(['Unrecognized TerminalConfig string: ''' state '''']);
            end
        end
        function res = TerminalConfig_code2str(code)
            switch code
                case DAQmxAnalogInput.DAQmx_Val_Cfg_Default
                    res = 'Default';
                case DAQmxAnalogInput.DAQmx_Val_RSE
                    res = 'RSE';
                case DAQmxAnalogInput.DAQmx_Val_NRSE
                    res = 'NRSE';
                case DAQmxAnalogInput.DAQmx_Val_Diff
                    res = 'Diff';
                case DAQmxAnalogInput.DAQmx_Val_PseudoDiff
                    res = 'PseudoDiff';
                otherwise
                    error(['Unrecognized TerminalConfig code: ' int2str(code)]);
            end
        end
        
    end
    
end

