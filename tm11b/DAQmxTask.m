classdef DAQmxTask < handle
    % DAQmxTask: MATLAB class implementation of DAQmx tasks.
    %  - Damien Loterie (05/2014)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % CONSTRUCTOR/DESTRUCTOR %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (SetAccess=private, GetAccess=protected)
        TaskHandle;
    end    
    methods
        function obj = DAQmxTask(name)
            % Default name
            if nargin==0
                name = '';
            end
            
            % Load library if needed
            DAQmxLoadLibrary;
            
            % Create new DAQmx task
            [ExitCode, ~, obj.TaskHandle] = calllib('NIDAQmx', ...
                                                    'DAQmxCreateTask', ...
                                                    name, ...
                                                    libpointer('voidPtr'));
                                                
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        function delete(obj)
            % Clear task
            [ExitCode, ~] = calllib('NIDAQmx',...
                                    'DAQmxClearTask',...
                                    obj.TaskHandle);
                                
            % Check errors
            DAQmxErrorCheck(ExitCode, 'warning');
            
%             % Debug
%             disp('Task cleared');
        end
    end
    
        
    %%%%%%%%%%%%%%%%%
    % DAQmx METHODS %
    %%%%%%%%%%%%%%%%%
    methods 
        function wait(obj, timeout)
            % Input check
            if nargin<2
                timeout = 10;
            end
            
            % Wait for end of task
            [ExitCode, ~] = calllib('NIDAQmx',...
                                    'DAQmxWaitUntilTaskDone', ...
                                    obj.TaskHandle, ...
                                    double(timeout));
                                     
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        function start(obj)
            % Start task
            [ExitCode, ~] = calllib('NIDAQmx',...
                                    'DAQmxStartTask', ...
                                    obj.TaskHandle);
                                     
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    
        function stop(obj)
            % Start task
            [ExitCode, ~] = calllib('NIDAQmx',...
                                    'DAQmxStopTask', ...
                                    obj.TaskHandle);
                                     
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        
        
    
    end  
    
    
    
    %%%%%%%%%%%%%%%%%%%%
    % DAQmx PROPERTIES %
    %%%%%%%%%%%%%%%%%%%%
    properties (SetAccess=private, GetAccess=protected, Dependent)
        TaskName;
    end
    properties (SetAccess=private, GetAccess=public, Dependent)
       	IsTaskDone;
    end
    methods
        function res = get.TaskName(obj)
            % Prepare output buffer
            BufferSize = 4096;
            
            % Get task name
            [ExitCode, ~, res] = calllib('NIDAQmx', ...
                                         'DAQmxGetTaskName', ...
                                          obj.TaskHandle, ...
                                          repmat(' ',BufferSize,1), ...
                                          uint32(BufferSize)); 
            
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
        function res = get.IsTaskDone(obj)
            % Check if task is done
            [ExitCode, ~, res] = calllib('NIDAQmx',...
                                         'DAQmxIsTaskDone',...
                                         obj.TaskHandle,...
                                         uint32(0));
                                     
            % Check errors
            DAQmxErrorCheck(ExitCode);
        end
    end
    
end

