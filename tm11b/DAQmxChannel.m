classdef DAQmxChannel < DAQmxTask
    % DAQmxChannel: Superclass that regroups all the methods and properties
    %               that are common to all types of channels.
    %
    %  - Damien Loterie (04/2015)
    
    %%%%%%%%%%%%%%%
    % CONSTRUCTOR %
    %%%%%%%%%%%%%%%
    methods
        function obj = DAQmxChannel()                                     
            % Call superclass constructor
            obj = obj@DAQmxTask;
        end
    end
    
    %%%%%%%%%%%%%%%%%
    % DAQmx METHODS %
    %%%%%%%%%%%%%%%%%
    methods
        function CfgDigEdgeStartTrig(obj, source, edge)
            % Translate edge
            edge = DAQmxChannel.EdgeType_str2code(edge);

            % Configure
            ExitCode = calllib('NIDAQmx', 'DAQmxCfgDigEdgeStartTrig', ...
                                          obj.TaskHandle, ...
                                          [source, 0], ...
                                          edge);

            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        function CfgImplicitTiming(obj, mode, number)
            % Translate edge
            mode = DAQmxChannel.SampleMode_str2code(mode);

            % Configure
            ExitCode = calllib('NIDAQmx', 'DAQmxCfgImplicitTiming', ...
                                          obj.TaskHandle, ...
                                          mode, ...
                                          uint64(number));

            % Check errors
            DAQmxErrorCheck(ExitCode);
        end

        function DisableStartTrig(obj)
            % Disable
            ExitCode = calllib('NIDAQmx', 'DAQmxDisableStartTrig', ...
                                          obj.TaskHandle);

            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        function CfgSampClkTiming(obj, source, rate, activeEdge, sampleMode, sampsPerChanToAcquire)
            % Translate edge
            sampleMode = DAQmxChannel.SampleMode_str2code(sampleMode);
            activeEdge = DAQmxChannel.EdgeType_str2code(activeEdge);
            
            % Configure
            ExitCode = calllib('NIDAQmx', 'DAQmxCfgSampClkTiming', ...
                                          obj.TaskHandle, ...
                                          [source; 0], ...
                                          double(rate),...
                                          activeEdge,...
                                          sampleMode,...
                                          uint64(sampsPerChanToAcquire));

            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%
    % DAQmx PROPERTIES %
    %%%%%%%%%%%%%%%%%%%%
    properties (Dependent, SetAccess=public, GetAccess=public)
        StartTriggerType;
        TriggerEdge;
        StartTriggerSource;
        StartTriggerRetriggerable;
        SampleMode;
        SampleQuantity;
        SampleClockActiveEdge;
        SampleClockRate;
        SampleClockSource;
        TimingType;
        AvailableSamples;
        OutputBufferSize;
        InputBufferSize;
    end
    methods
        % StartTriggerType
        function res = get.StartTriggerType(obj)
            % Get StartTriggerType
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetStartTrigType', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.StartTriggerType_code2str(code);
        end
        function set.StartTriggerType(obj, state)
            % Translate value
            code = DAQmxChannel.StartTriggerType_str2code(state);
            
            % Set StartTriggerType
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetStartTrigType', ...
                                    obj.TaskHandle, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % TriggerEdge
        function res = get.TriggerEdge(obj)
            % Get TriggerEdge
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetStartTrigType', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.EdgeType_code2str(code);
        end
        function set.TriggerEdge(obj, state)
            % Translate value
            code = DAQmxChannel.EdgeType_str2code(state);
            
            % Set TriggerEdge
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetStartTrigType', ...
                                    obj.TaskHandle, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % StartTriggerSource
        function res = get.StartTriggerSource(obj)
            % Prepare output buffer
            BufferSize = 4096;
            
            % Get StartTriggerSource
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetDigEdgeStartTrigSrc', ...
                                         obj.TaskHandle, ...
                                         repmat(' ',BufferSize,1), ...
                                         uint32(BufferSize));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.StartTriggerSource(obj, source)
            % Set StartTriggerSource
            [ExitCode, ~, ~] = calllib('NIDAQmx', ...
                                       'DAQmxSetDigEdgeStartTrigSrc', ...
                                       obj.TaskHandle, ...
                                       [source(:); 0]);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % SampleMode
        function res = get.SampleMode(obj)
            % Get SampleMode
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetSampQuantSampMode', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.SampleMode_code2str(code);
        end
        function set.SampleMode(obj, state)
            % Translate value
            code = DAQmxChannel.SampleMode_str2code(state);
            
            % Set SampleMode
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetSampQuantSampMode', ...
                                    obj.TaskHandle, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % SampleQuantity
        function res = get.SampleQuantity(obj)
            % Get SampleQuantity
            [ExitCode, ~, res] =  calllib('NIDAQmx', ...
                                          'DAQmxGetSampQuantSampPerChan', ...
                                          obj.TaskHandle, ...
                                          uint64(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.SampleQuantity(obj, number)
            % Set SampleQuantity
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetSampQuantSampPerChan', ...
                                    obj.TaskHandle, ...
                                    uint64(number));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % TimingType
        function res = get.TimingType(obj)
            % Get TimingType
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetSampTimingType', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.TimingType_code2str(code);
        end
        function set.TimingType(obj, state)
            % Translate value
            code = DAQmxChannel.TimingType_str2code(state);
            
            % Set TimingType
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetSampTimingType', ...
                                    obj.TaskHandle, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % StartTriggerRetriggerable
        function res = get.StartTriggerRetriggerable(obj)
            % Get StartTriggerRetriggerable
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetStartTrigRetriggerable', ...
                                         obj.TaskHandle, ...
                                         int32(0));
                                                              
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Return value
            res = logical(res);
        end
        function set.StartTriggerRetriggerable(obj, val)
            % Set StartTriggerRetriggerable
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetStartTrigRetriggerable', ...
                                    obj.TaskHandle, ...
                                    int32(logical(val)));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % SampleClockActiveEdge
        function res = get.SampleClockActiveEdge(obj)
            % Get TimingType
            [ExitCode, ~, code] = calllib('NIDAQmx', ...
                                          'DAQmxGetSampClkTimebaseActiveEdge', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
            
            % Retrieve value
            res = DAQmxChannel.EdgeType_code2str(code);
        end
        function set.SampleClockActiveEdge(obj, edge)
            % Translate value
            code = DAQmxChannel.EdgeType_str2code(edge);
            
            % Set TimingType
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetSampClkTimebaseActiveEdge', ...
                                    obj.TaskHandle, ...
                                    int32(code));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % SampleClockRate
        function res = get.SampleClockRate(obj)
            % Get TimingType
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                          'DAQmxGetSampClkTimebaseRate', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.SampleClockRate(obj, rate)
            % Set TimingType
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetSampClkTimebaseRate', ...
                                    obj.TaskHandle, ...
                                    rate);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % SampleClockSource
        function res = get.SampleClockSource(obj)
            % Prepare output buffer
            BufferSize = 4096;
            
            % Get task name
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetSampClkTimebaseSrc', ...
                                          obj.TaskHandle, ...
                                          repmat(' ',BufferSize,1), ...
                                          uint32(BufferSize)); 
            
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.SampleClockSource(obj, source)
            % Get task name
            ExitCode = calllib('NIDAQmx', ...
                               'DAQmxSetSampClkTimebaseSrc', ...
                               obj.TaskHandle, ...
                               [source(:); 0]); 
            
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % AvailSampPerChan
        function res = get.AvailableSamples(obj)
            % Get
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetReadAvailSampPerChan', ...
                                          obj.TaskHandle, ...
                                          uint32(0)); 
                        
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % OutputBufferSize
        function res = get.OutputBufferSize(obj)
            % Get
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                          'DAQmxGetBufOutputBufSize', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.OutputBufferSize(obj, bufSize)
            % Set
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetBufOutputBufSize', ...
                                    obj.TaskHandle, ...
                                    bufSize);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        % InputBufferSize
        function res = get.InputBufferSize(obj)
            % Get
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                          'DAQmxGetBufInputBufSize', ...
                                          obj.TaskHandle, ...
                                          int32(0));
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function set.InputBufferSize(obj, bufSize)
            % Set
            [ExitCode, ~] = calllib('NIDAQmx', ...
                                    'DAQmxSetBufInputBufSize', ...
                                    obj.TaskHandle, ...
                                    bufSize);
                                                               
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
    end
    
    %%%%%%%%%%%%%
    % CONSTANTS %
    %%%%%%%%%%%%%
    properties (Constant, Hidden)
        % Implicit timing
        DAQmx_Val_FiniteSamps        = int32(10178);
        DAQmx_Val_ContSamps          = int32(10123);
        DAQmx_Val_HWTimedSinglePoint = int32(12522);
        
        % Trigger active edge
        DAQmx_Val_Rising        = int32(10280); 
        DAQmx_Val_Falling       = int32(10171);
        
        % Trigger type
        DAQmx_Val_DigEdge       = int32(10150);
        DAQmx_Val_DigPattern    = int32(10398);
        DAQmx_Val_AnlgEdge      = int32(10099);
        DAQmx_Val_AnlgWin       = int32(10103);
        DAQmx_Val_None          = int32(10230);
        
        % Timing type
        DAQmx_Val_SampClk          = int32(10388);
        DAQmx_Val_BurstHandshake   = int32(12548);
        DAQmx_Val_Handshake        = int32(10389);
        DAQmx_Val_Implicit         = int32(10451);
        DAQmx_Val_OnDemand         = int32(10390);
        DAQmx_Val_ChangeDetection  = int32(12504);
        DAQmx_Val_PipelinedSampClk = int32(14668);
        
        % Read parameters
        DAQmx_Val_Auto              = int32(-1);
        DAQmx_Val_WaitInfinitely    = double(-1);
        DAQmx_Val_GroupByChannel    = int32(0);
        DAQmx_Val_GroupByScanNumber = int32(1);	
    end
    
    methods (Static, Access=private)
       % StartTriggerType translations
       function res = StartTriggerType_str2code(state)
            switch lower(state)
                case 'immediate'
                    res = DAQmxChannel.DAQmx_Val_None;
                case 'digital edge'
                    res = DAQmxChannel.DAQmx_Val_DigEdge;
                case 'digital pattern'
                    res = DAQmxChannel.DAQmx_Val_DigPattern;
                case 'analog edge'
                    res = DAQmxChannel.DAQmx_Val_AnlgEdge;
                case 'analog window'
                    res = DAQmxChannel.DAQmx_Val_AnlgWin;
                otherwise
                    error(['Unrecognized StartTriggerType string: ''' state '''']);
            end
        end
        function res = StartTriggerType_code2str(code)
            switch code
                case DAQmxChannel.DAQmx_Val_None
                    res = 'immediate';
                case DAQmxChannel.DAQmx_Val_DigEdge
                    res = 'digital edge';
                case DAQmxChannel.DAQmx_Val_DigPattern
                    res = 'digital pattern';
                case DAQmxChannel.DAQmx_Val_AnlgEdge
                    res = 'analog edge';
                case DAQmxChannel.DAQmx_Val_AnlgWin
                    res = 'analog window';
                otherwise
                    error(['Unrecognized StartTriggerType code: ' int2str(code)]);
            end
        end 
        
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
                    error(['Unrecognized TriggerEdge string: ''' state '''']);
            end
        end
        function res = EdgeType_code2str(code)
            switch code
                case DAQmxChannel.DAQmx_Val_Rising
                    res = 'rising';
                case DAQmxChannel.DAQmx_Val_Falling
                    res = 'falling';
                case DAQmxChannel.DAQmx_Val_None
                    res = 'none';
                otherwise
                    error(['Unrecognized TriggerEdge code: ' int2str(code)]);
            end
        end 
        
       % SampleMode translations
       function res = SampleMode_str2code(state)
            switch lower(state)
                case 'finite'
                    res = DAQmxChannel.DAQmx_Val_FiniteSamps;
                case 'continuous'
                    res = DAQmxChannel.DAQmx_Val_ContSamps;  
                case 'hardware timed single point'
                    res = DAQmxChannel.DAQmx_Val_HWTimedSinglePoint;      
                otherwise
                    error(['Unrecognized SampleMode string: ''' state '''']);
            end
        end
        function res = SampleMode_code2str(code)
            switch code
                case DAQmxChannel.DAQmx_Val_FiniteSamps
                    res = 'finite';
                case DAQmxChannel.DAQmx_Val_ContSamps
                    res = 'continuous';
                case DAQmxChannel.DAQmx_Val_ContDAQmx_Val_HWTimedSinglePointSamps
                    res = 'hardware timed single point';
                otherwise
                    error(['Unrecognized SampleMode code: ' int2str(code)]);
            end
        end 
        
       % TimingType translations
       function res = TimingType_str2code(state)
            switch lower(state)
                case 'sample clock'
                    res = DAQmxChannel.DAQmx_Val_SampClk; 
                case 'handshake'
                    res = DAQmxChannel.DAQmx_Val_Handshake;
                case 'burst handshake'
                    res = DAQmxChannel.DAQmx_Val_BurstHandshake;  
                case 'pipelined sample clock'
                    res = DAQmxChannel.DAQmx_Val_PipelinedSampClk;
                case 'on demand'
                    res = DAQmxChannel.DAQmx_Val_OnDemand;  
                case 'implicit'
                    res = DAQmxChannel.DAQmx_Val_Implicit;
                case 'change detection'
                    res = DAQmxChannel.DAQmx_Val_ChangeDetection;    
                otherwise
                    error(['Unrecognized TimingType string: ''' state '''']);
            end
        end
        function res = TimingType_code2str(code)
            switch code
                case DAQmxChannel.DAQmx_Val_SampClk
                    res = 'sample clock'; 
                case DAQmxChannel.DAQmx_Val_Handshake
                    res = 'handshake';
                case DAQmxChannel.DAQmx_Val_BurstHandshake
                    res = 'burst handshake';  
                case DAQmxChannel.DAQmx_Val_PipelinedSampClk
                    res = 'pipelined sample clock';
                case DAQmxChannel.DAQmx_Val_OnDemand
                    res = 'on demand';  
                case DAQmxChannel.DAQmx_Val_Implicit
                    res = 'implicit';
                case DAQmxChannel.DAQmx_Val_ChangeDetection
                    res = 'change detection';  
                otherwise
                    error(['Unrecognized TimingType code: ' int2str(code)]);
            end
        end 
    end
    
end

