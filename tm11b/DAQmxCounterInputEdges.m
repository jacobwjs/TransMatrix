classdef DAQmxCounterInputEdges < DAQmxChannel
    % DAQmxCounterInputEdges: Interface to counter input functions
    %                         in the NI DAQmx C library. This interface
    %                         only supports edge counting.
    %
    % Allows to use advanced features of the NI DAQmx counters.
    % Refer to the NI X-series manual for more information about the 
    % implemented functions.
    %
    % Note: As of April 2016, not all of the DAQmx library functions are
    %       implemented (only the ones I needed). To implement new
    %       functions, read the NI-DAQmx C Reference manual and follow the
    %       same patterns as in the already implemented methods.
    %
    %  - Damien Loterie (04/2016)
    
    %%%%%%%%%%%%%%%
    % CONSTRUCTOR %
    %%%%%%%%%%%%%%%
    properties (SetAccess=private, GetAccess=public)
       PhysicalChannel; 
    end
    
    methods
        function obj = DAQmxCounterInputEdges(PhysicalChannel, ...
                                              ActiveEdge, ...
                                              CountDirection, ...
                                              InitialCount)                   
            
           
            
            % Input processing
            narginchk(1,4);
            if nargin<2
                ActiveEdge = DAQmxChannel.DAQmx_Val_Rising;
            else
                ActiveEdge = EdgeType_str2code(ActiveEdge);
            end
            if nargin<3
                CountDirection = DAQmxCounterInput.DAQmx_Val_CountUp;
            else
                CountDirection = CountDirection_str2code(CountDirection);
            end
            if nargin<4
                InitialCount = 0;
            end
            InitialCount = uint32(InitialCount);
                 
            % Call superclass constructor
            obj = obj@DAQmxChannel;
            
            % Create channel
            obj.PhysicalChannel = PhysicalChannel;
            ExitCode = calllib('NIDAQmx','DAQmxCreateCICountEdgesChan', ...  
                                         obj.TaskHandle, ...        % Task handle
                                         obj.PhysicalChannel, ...   % Device/Channel
                                         '', ...                    % Channel name
                                         ActiveEdge, ...            % Type of edges to count
                                         InitialCount, ...          % Initial count
                                         CountDirection);           % Count direction
                                                
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
                    = calllib('NIDAQmx','DAQmxReadCounterU32', ...  
                                         obj.TaskHandle, ...        % Task handle
                                         int32(n), ...              % Number of samples per channel
                                         double(timeout), ...       % Timeout
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
        ActiveEdge;
        CountResetEnable;
        CountResetValue;
        CountResetSource;
        CountResetEdge;
    end
    methods
        
        % TriggerEdge translations
       function res = EdgeType_str2code(state)
            switch lower(state)
                case 'rising'
                    res = DAQmxChannel.DAQmx_Val_Rising;
                case 'falling'
                    res = DAQmxChannel.DAQmx_Val_Falling;
                case 'none'
                    res = DAQmxChannel.DAQmx_Val_None;    
                otherwise
                    error(['Unrecognized EdgeType string: ''' state '''']);
            end
        end
        
        
        % ActiveEdge
        function res = get.ActiveEdge(obj)
            % Get ActiveEdge
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetCICountEdgesActiveEdge', ...
                                          obj.TaskHandle, ...
                                          obj.PhysicalChannel, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.EdgeType_code2str(code);
        end
        function set.ActiveEdge(obj, state)
            % Translate value
            code = DAQmxChannel.EdgeType_str2code(state);
            
            % Set ActiveEdge
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetCICountEdgesActiveEdge',  ...
                                    obj.TaskHandle, ...
                                    obj.PhysicalChannel, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end  
        
        % CountResetEnable
        function res = get.CountResetEnable(obj)
            % Get CountResetEnable
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetCICountEdgesCountResetEnable',  ...
                                         obj.TaskHandle, ...
                                         obj.PhysicalChannel, ...
                                         int32(0));
                                                              
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Return value
            res = logical(res);
        end
        function set.CountResetEnable(obj, val)
            % Set CountResetEnable
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetCICountEdgesCountResetEnable',  ...
                                    obj.TaskHandle, ...
                                    obj.PhysicalChannel, ...
                                    int32(logical(val)));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % CountResetValue
        function res = get.CountResetValue(obj)
            % Get CountResetValue
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetCICountEdgesCountResetResetCount',  ...
                                         obj.TaskHandle, ...
                                         obj.PhysicalChannel, ...
                                         uint32(0));
                                                              
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.CountResetValue(obj, val)
            % Set CountResetValue
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetCICountEdgesCountResetResetCount',  ...
                                    obj.TaskHandle, ...
                                    obj.PhysicalChannel, ...
                                    uint32(val));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % CountResetSource
        function res = get.CountResetSource(obj)
            % Prepare output buffer
            BufferSize = 4096;
            
            % Get CountResetSource
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetCICountEdgesCountResetTerm', ...
                                         obj.TaskHandle, ...
                                         obj.PhysicalChannel, ...
                                         repmat(' ',BufferSize,1), ...
                                         uint32(BufferSize));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.CountResetSource(obj, source)
            % Set CountResetSource
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetCICountEdgesCountResetTerm', ...
                                       obj.TaskHandle, ...
                                       obj.PhysicalChannel, ...
                                       [source(:); 0]);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % CountResetEdge
        function res = get.CountResetEdge(obj)
            % Get CountResetEdge
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetCICountEdgesCountResetActiveEdge', ...
                                          obj.TaskHandle, ...
                                          obj.PhysicalChannel, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.EdgeType_code2str(code);
        end
        function set.CountResetEdge(obj, state)
            % Translate value
            code = DAQmxChannel.EdgeType_str2code(state);
            
            % Set CountResetEdge
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetCICountEdgesCountResetActiveEdge',  ...
                                    obj.TaskHandle, ...
                                    obj.PhysicalChannel, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end 
        
    end
    
    %%%%%%%%%%%%%
    % CONSTANTS %
    %%%%%%%%%%%%%
    properties (Constant, Access=private)
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
        DAQmx_Val_CountUp       = int32(10128);
        DAQmx_Val_CountDown     = int32(10124);
        DAQmx_Val_ExtControlled = int32(10326);

    end
    
    methods (Static, Access=private)
        % CountDirection translations
        function res = CountDirection_str2code(state)
            switch lower(state)
                case 'up'
                    res = DAQmxCounterInputEdges.DAQmx_Val_CountUp;
                case 'down'
                    res = DAQmxCounterInputEdges.DAQmx_Val_CountDown;
                case 'ext'
                    res = DAQmxCounterInputEdges.DAQmx_Val_ExtControlled;
                otherwise
                    error(['Unrecognized CountDirection string: ''' state '''']);
            end
        end
        function res = CountDirection_code2str(code)
            switch code
                case DAQmxCounterInputEdges.DAQmx_Val_CountUp
                    res = 'up';
                case DAQmxCounterInputEdges.DAQmx_Val_CountDown
                    res = 'down';
                case DAQmxCounterInputEdges.DAQmx_Val_ExtControlled
                    res = 'ext';
                otherwise
                    error(['Unrecognized CountDirection code: ' int2str(code)]);
            end
        end
        
        
        
%        % TriggerEdge translations
%        function res = EdgeType_str2code(state)
%             switch lower(state)
%                 case 'rising'
%                     res = DAQmxChannel.DAQmx_Val_Rising;
%                 case 'falling'
%                     res = DAQmxChannel.DAQmx_Val_Falling;
%                 case 'none'
%                     res = DAQmxChannel.DAQmx_Val_None;    
%                 otherwise
%                     error(['Unrecognized EdgeType string: ''' state '''']);
%             end
%         end
        function res = EdgeType_code2str(code)
            switch code
                case DAQmxChannel.DAQmx_Val_Rising
                    res = 'rising';
                case DAQmxChannel.DAQmx_Val_Falling
                    res = 'falling';
                case DAQmxChannel.DAQmx_Val_None
                    res = 'none';
                otherwise
                    error(['Unrecognized EdgeType code: ' int2str(code)]);
            end
        end 
                      
    end
    
end

