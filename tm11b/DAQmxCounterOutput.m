classdef DAQmxCounterOutput < DAQmxChannel
    % DAQmxCounterOutput: Interface to counter output functions
    %                     in the NI DAQmx C library.
    %
    % Allows to use advanced features of the NI DAQmx counters.
    % Refer to the NI X-series manual for more information about the 
    % implemented functions.
    %
    % Note: As of May 2014, not all of the DAQmx library functions are
    %       implemented (only the ones I needed). To implement new
    %       functions, read the NI-DAQmx C Reference manual and follow the
    %       same patterns as in the already implemented methods.
    %
    %  - Damien Loterie (05/2014)
    
    %%%%%%%%%%%%%%%
    % CONSTRUCTOR %
    %%%%%%%%%%%%%%%
    properties (SetAccess=private, GetAccess=public)
       PhysicalChannel; 
    end
    
    methods
        function obj = DAQmxCounterOutput(PhysicalChannel, ...
                                          HighTime, ...
                                          LowTime, ...
                                          InitialDelay, ...
                                          IdleState)                   
            % Input processing
            narginchk(1,5);
            if nargin<5
                IdleState = DAQmxCounterOutput.DAQmx_Val_Low;
            else
                IdleState = IdleState_str2code(IdleState);
            end
            if nargin<4 || isempty(InitialDelay)
               InitialDelay = DAQmxCounterOutput.CounterTimeMin;
            end
            if nargin<3 || isempty(LowTime)
               LowTime = DAQmxCounterOutput.CounterTimeMin;
            end
            if nargin<2 || isempty(HighTime)
               HighTime = DAQmxCounterOutput.CounterTimeMin;
            end
            
            % Range check
            if InitialDelay<DAQmxCounterOutput.CounterTimeMin ...
            	|| InitialDelay>DAQmxCounterOutput.CounterTimeMax ...
            	|| LowTime<DAQmxCounterOutput.CounterTimeMin ...
                || LowTime>DAQmxCounterOutput.CounterTimeMax ...
                || HighTime<DAQmxCounterOutput.CounterTimeMin ...
                || HighTime>DAQmxCounterOutput.CounterTimeMax
                 error(['The values for InitialDelay, LowTime and HighTime must be \n'...
                        'in the range [' ...
                        num2str(DAQmxCounterOutput.CounterTimeMin) ...
                        '; ' ...
                        num2str(DAQmxCounterOutput.CounterTimeMax) ...
                        ']. \n\n' ...
                        'Current values are: \n' ...
                        'InitialDelay: %d \n' ...
                        'HighTime:     %d \n' ...
                        'LowTime:      %d \n' ...
                        ],...
                        InitialDelay,...
                        HighTime,...
                        LowTime);
            end
                                      
            % Call superclass constructor
            obj = obj@DAQmxChannel;
            
            % Create channel
            obj.PhysicalChannel = PhysicalChannel;
            ExitCode = calllib('NIDAQmx','DAQmxCreateCOPulseChanTime', ...  
                                         obj.TaskHandle, ...        % Task handle
                                         obj.PhysicalChannel, ...   % Device/Channel
                                         '', ...                    % Channel name
                                         DAQmxCounterOutput.DAQmx_Val_Seconds, ...     % Units of time
                                         IdleState, ...             % Idle state
                                         InitialDelay, ...          % Initial delay
                                         LowTime, ...               % Low time
                                         HighTime);                 % High time
            if (ExitCode<0)
                disp(['InitialDelay:' num2str(InitialDelay)]);
                disp(['LowTime:'      num2str(LowTime)]);
                disp(['HighTime:'     num2str(HighTime)]);
            end
                                                
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    end

    %%%%%%%%%%%%%%%%%%%%
    % DAQmx PROPERTIES %
    %%%%%%%%%%%%%%%%%%%%
    properties (Dependent, SetAccess=public, GetAccess=public)
        IdleState;
        HighTime;
        LowTime;
        InitialDelay;
        EnableInitialDelayOnRetrigger;
    end
    methods
        % IdleState
        function res = get.IdleState(obj)
            % Get IdleState
            [ExitCode, ~, ~,code] = calllib('NIDAQmx', ...
                                            'DAQmxGetCOPulseIdleState', ...
                                            obj.TaskHandle, ...
                                            obj.PhysicalChannel, ...
                                            int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxCounterOutput.IdleState_code2str(code);
        end
        function set.IdleState(obj, state)
            % Translate value
            code = DAQmxCounterOutput.IdleState_str2code(state);
            
            % Set IdleState
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCOPulseIdleState', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % HighTime
        function res = get.HighTime(obj)
            % Get HighTime
            [ExitCode, ~, ~,res] = calllib('NIDAQmx', ...
                                            'DAQmxGetCOPulseHighTime', ...
                                            obj.TaskHandle, ...
                                            obj.PhysicalChannel, ...
                                            double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);

        end
        function set.HighTime(obj, time)
            % Check value
            time = double(time);
            if     time<DAQmxCounterOutput.CounterTimeMin ...
            	|| time>DAQmxCounterOutput.CounterTimeMax
                error(['The values for InitialDelay, LowTime and HighTime must be in the range [' ...
                      num2str(DAQmxCounterOutput.CounterTimeMin) ...
                      '; ' ...
                      num2str(DAQmxCounterOutput.CounterTimeMax) ...
                      ']']);
            end
            
            % Set HightTime
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCOPulseHighTime', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       time);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end

        % LowTime
        function res = get.LowTime(obj)
            % Get LowTime
            [ExitCode, ~, ~,res] = calllib('NIDAQmx', ...
                                            'DAQmxGetCOPulseLowTime', ...
                                            obj.TaskHandle, ...
                                            obj.PhysicalChannel, ...
                                            double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);

        end
        function set.LowTime(obj, time)
            % Check value
            time = double(time);
            if     time<DAQmxCounterOutput.CounterTimeMin ...
            	|| time>DAQmxCounterOutput.CounterTimeMax
                error(['The values for InitialDelay, LowTime and HighTime must be in the range [' ...
                      num2str(DAQmxCounterOutput.CounterTimeMin) ...
                      '; ' ...
                      num2str(DAQmxCounterOutput.CounterTimeMax) ...
                      ']']);
            end
            
            % Set LowTime
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCOPulseLowTime', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       time);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % InitialDelay
        function res = get.InitialDelay(obj)
            % Get InitialDelay
            [ExitCode, ~, ~,res] = calllib('NIDAQmx', ...
                                            'DAQmxGetCOPulseTimeInitialDelay', ...
                                            obj.TaskHandle, ...
                                            obj.PhysicalChannel, ...
                                            double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);

        end
        function set.InitialDelay(obj, time)
            % Check value
            time = double(time);
            if     time<DAQmxCounterOutput.CounterTimeMin ...
            	|| time>DAQmxCounterOutput.CounterTimeMax
                error(['The values for InitialDelay, LowTime and HighTime must be in the range [' ...
                      num2str(DAQmxCounterOutput.CounterTimeMin) ...
                      '; ' ...
                      num2str(DAQmxCounterOutput.CounterTimeMax) ...
                      ']']);
            end
            
            % Set InitialDelay
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCOPulseTimeInitialDelay', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       time);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % EnableInitialDelayOnRetrigger
        function res = get.EnableInitialDelayOnRetrigger(obj)
            % Get EnableInitialDelayOnRetrigger
            [ExitCode, ~, ~,res] = calllib('NIDAQmx', ...
                                           'DAQmxGetCOEnableInitialDelayOnRetrigger', ...
                                           obj.TaskHandle, ...
                                           obj.PhysicalChannel, ...
                                           double(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Return value
            res = logical(res);
        end
        function set.EnableInitialDelayOnRetrigger(obj, val)
            % Set EnableInitialDelayOnRetrigger
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCOEnableInitialDelayOnRetrigger', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       int32(logical(val)));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
                
    end
    
    %%%%%%%%%%%%%
    % CONSTANTS %
    %%%%%%%%%%%%%
    properties (Constant, GetAccess=public) %Access=private)
        % Counter output limit values
        % Note: The values below are hardcoded for my NI PCIe-6323.
        %       You may have to change them for other cards.
        CounterTimebaseRate = 100e6;
        CounterMaximumCount = 4294967295;
        CounterTimeMin = 2/DAQmxCounterOutput.CounterTimebaseRate;
        CounterTimeMax = DAQmxCounterOutput.CounterMaximumCount/DAQmxCounterOutput.CounterTimebaseRate;
        
        % Units for HighTime, LowTime and InitialDelay
        DAQmx_Val_Seconds       = int32(10364);

        % Idle state
        DAQmx_Val_Low           = int32(10214);
        DAQmx_Val_High          = int32(10192);

    end
    
    methods (Static, Access=private)
        % IdleState translations
        function res = IdleState_str2code(state)
            switch lower(state)
                case 'high'
                    res = DAQmxCounterOutput.DAQmx_Val_High;
                case 'low'
                    res = DAQmxCounterOutput.DAQmx_Val_Low;
                otherwise
                    error(['Unrecognized IdleState string: ''' state '''']);
            end
        end
        function res = IdleState_code2str(code)
            switch code
                case DAQmxCounterOutput.DAQmx_Val_Low
                    res = 'low';
                case DAQmxCounterOutput.DAQmx_Val_High
                    res = 'high';
                otherwise
                    error(['Unrecognized IdleState code: ' int2str(code)]);
            end
        end
    end
    
end

