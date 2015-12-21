% MATLAB class to interface MATLAB with the fullscreen display program
%  - Damien Loterie (11/2013)
%
% Based on:
% http://www.mathworks.ch/matlabcentral/fileexchange/38964-example-matlab-class-wrapper-for-a-c++-class


classdef dx_fullscreen < hgsetget
    
    
    properties (SetAccess = private, Hidden = true)
        % Handle to the underlying C++ class instance
        objectHandle; 
        
        % Sequence data in MATLAB
        sequenceFunction;
        sequenceFramesTotal;
        sequenceFramesSent;
        sequenceTiming;
        sequenceReady = false; 
    end
    

    methods        
        % Constructor - Create a new C++ class instance 
        function this = dx_fullscreen(options)
            % Check for reconnection
            if nargin==0
                % Start application if it is not running already
                if ~dx_fullscreen_is_running
                    dx_fullscreen.startup;
                end
                
                % Open connection
                this.objectHandle = dx_fullscreen_mex('new');
                this.openFiles();
                return;
            elseif nargin==1 && isstruct(options)
                % Check if application is running.
                if dx_fullscreen_is_running
                    % If it is, abort.
                    error('Fullscreen application is already running. Cannot start a new instance with different parameters.');
                else
                    % Otherwise, start it.
                    dx_fullscreen.startup(options);
                    
                    % Open connection
                    this.objectHandle = dx_fullscreen_mex('new');
                    this.openFiles();
                    return;
                end

            else
               error('Unexpected argument'); 
            end
            
        end
        
        % Destructor - Destroy the C++ class instance
        function delete(this)
            this.closeFiles();
            dx_fullscreen_mex('delete', this.objectHandle);
        end
        
        % Show - Show a single frame
        function show(this, frame)
            
            % Check if a sequence was loaded before
            if (this.sequenceReady)
                this.clearSequence();
                warning('Calling ''show'' caused the currently loaded sequence to be cleared.');
            end
            
            % Reset signal
            this.setConfig('run', false);
            this.setConfig('bufferFrameIndex', 0);
            this.resetSignal();
            
            % Display the given frame
            this.setConfig('frameRateDivider', 0);
            this.putData(0, frame);
            this.setConfig('run', true);
            
            % Wait for display
            this.waitForSignal();
        end
        
        % Quit - Send the quit signal to the application
        function quit(this)
            this.setConfig('quit', true);
        end
        
        % loadSequence - configure the system for showing a movie
        function loadSequence(this, varargin)
              % dx_fullscreen.loadSequence(data)
              % dx_fullscreen.loadSequence(data, divider)
              % dx_fullscreen.loadSequence(function, n)
              % dx_fullscreen.loadSequence(function, n, divider)
              %
              % Loads the sequence data to use during play()
               
            % Input validation
            if nargin<2
               error('At least one parameter is needed.'); 
            end
            
            if isa(varargin{1},'uint8')
               % Case where the data is precalculated

               % Validate input
               data = varargin{1};
               if numel(size(data))>3
                  error('The input data must be 3-dimensional at most.'); 
               end
               
               % Store the data as a function
               this.sequenceFunction = @(n)(data(:,:,n));
               this.sequenceFramesTotal = size(data,3);
               
               % Read divider value
               if nargin>=3
                   divider = int32(varargin{2});
                   if numel(divider)>1
                       error('The divider must be a single value, not an array.');
                   end
               else
                   divider = int32(1);
               end
               
            elseif isa(varargin{1},'function_handle')
                % Case where the data is calculated on the fly
                
                % Validate
                if nargin<3
                   error('When supplying a function handle, the total number of frames to calculate must also be specified as a second parameter.'); 
                end

                % Read function
                this.sequenceFunction = varargin{1};
                if numel(this.sequenceFunction)>1
                       error('The function must be a single function, not an array of functions.');
                end
                
                % Read the number of frames
                this.sequenceFramesTotal = int32(varargin{2});
                if numel(this.sequenceFramesTotal)>1 || this.sequenceFramesTotal<=0
                       error('The number of frames must be a single positive integer value, not an array.');
                end
                
               % Read divider value
               if nargin>=4
                   divider = int32(varargin{3});
                   if numel(divider)>1 || divider<=0
                       error('The divider must be a single positive integer value, not an array.');
                   end
               else
                   divider = int32(1);
               end
                
            else
                error('The data source must be a real uint8 array, or a function handle.'); 
            end

            % Configure
            this.setConfig('run', false);
            this.setConfig('bufferFrameIndex',int32(0));
            this.setConfig('frameCounter',int32(0));
            this.setConfig('frameRateDivider',divider);
            
            % Prepare the first frames
            bufferFrameSize = this.getConfig('bufferFrameSize');
            if bufferFrameSize<=1
               error('Buffer size is too small. The buffer must hold at least 2 frames.'); 
            end
            if (this.sequenceFramesTotal > bufferFrameSize)
                % Load the buffer with as much frames as possible
                ticID = tic;
                framesToLoad = this.sequenceFunction(1:bufferFrameSize);
                timeToLoad = toc(ticID);
                
                % Display a warning if frame generation is too slow
                fpsNeeded = this.getConfig('refreshRate')/divider;
                fpsEffective = bufferFrameSize/timeToLoad;
                if (fpsEffective <= 0.80*fpsNeeded)
                    warning('dx_fullscreen:slowSequenceFunction',...
                            ['The frame rate of the input data generation (' num2str(round(fpsEffective*10)/10) 'fps) ' ...
                             'may not be fast enough to keep up with the current display parameters (' num2str(round(fpsNeeded*10)/10) 'fps)']);
                end
            else
                % Load all frames into the buffer
                framesToLoad = this.sequenceFunction(1:this.sequenceFramesTotal);
            end
            
            % Validate and load the data
            if (size(framesToLoad,1)~=this.getConfig('frameWidth') ...
               || size(framesToLoad,2)~=this.getConfig('frameHeight') );
                error('The input data does not have the right dimensions.'); 
            end
            if (~isa(framesToLoad,'uint8'));
                error(['The data source does not produce the right type (must be ''uint8'' instead of ''' class(framesToLoad) ''').']); 
            end
            this.putData(0, framesToLoad);
            this.sequenceFramesSent = size(framesToLoad,3);

            % Reset the signal
            this.resetSignal();
            
            % Set the stop point at the end of the currently loaded part of the stream
            this.setConfig('stopAfterFrame', this.sequenceFramesSent);
            
            % Set the signal to ask for more data at the half of the
            % buffer, if needed.
            if (this.sequenceFramesTotal > bufferFrameSize)
                this.setConfig('signalOnFrame',  round(bufferFrameSize/2));
            else
                this.setConfig('signalOnFrame',  0);
            end
            
            % Prepare the time output
            this.sequenceTiming = zeros(this.sequenceFramesTotal,1);

            % Mark the sequence as ready
            this.sequenceReady = true;
        end
        
        function clearSequence(this)
            clear this.sequenceFunction ...
                  this.sequenceFramesTotal ...
                  this.sequenceFramesSent ...
                  this.sequenceTiming;
            this.sequenceReady = false; 
        end
        
        function res = play(this)
            % Check if data is loaded properly first
            if (~this.sequenceReady)
                error('Please load a sequence first using loadSequence(...).');
            end

            % Run
            this.sequenceReady = false;
            this.setConfig('run', true);

            % Get buffer information
            bufferFrameSize = this.getConfig('bufferFrameSize');
            
            % Wait for first signal
            this.waitForSignal();
            
            % Feed buffer with more information as needed
            frameCounter = this.getConfig('frameCounter');
            while (frameCounter~=this.sequenceFramesTotal)
                % Get the signal and stop points
                signalOnFrame = this.getConfig('signalOnFrame');
                stopAfterFrame = this.getConfig('stopAfterFrame');
                
                % Find out which part of the buffer we can fill.
                % * Everything before signalOnFrame can be overwritten.
                % * Everything else until stopAfterFrame must be kept.
                signalIndexInBuffer = mod(signalOnFrame-1,  bufferFrameSize);
                stopIndexInBuffer   = mod(stopAfterFrame-1, bufferFrameSize);
                if (stopIndexInBuffer<signalIndexInBuffer)
                   % Fill from stop to signal
                   % (presumably, this is the second half of the buffer)
                   startIndex = stopIndexInBuffer+1;
                   numberOfFramesToTransfer = signalIndexInBuffer-stopIndexInBuffer;
                else
                   % Fill from stop to end of buffer, and from start of
                   % buffer to signal.
                   % (presumably, the stop is at the end of the buffer
                   %  and we will only fill the first half)
                   startIndex = [stopIndexInBuffer+1, 0];
                   numberOfFramesToTransfer = [bufferFrameSize-stopIndexInBuffer-1, signalIndexInBuffer+1];
                   if (numberOfFramesToTransfer(1)==0)
                      startIndex = startIndex(2);
                      numberOfFramesToTransfer = numberOfFramesToTransfer(2);
                   else
                      error('Unhandled case of a two-part buffer copy. The code must be rewritten to handle this case.'); 
                      % Note: this also affects the readout of the timing
                   end
                end
                
                % Check if you've reached the end of the sequence
                if ((this.sequenceFramesSent+numberOfFramesToTransfer) > this.sequenceFramesTotal)
                    numberOfFramesToTransfer = this.sequenceFramesTotal-this.sequenceFramesSent;
                end
                
                % Fill the buffer
                framesToTransfer = (this.sequenceFramesSent) + (1:numberOfFramesToTransfer);
                this.putData(startIndex, this.sequenceFunction(framesToTransfer));
                this.sequenceFramesSent = this.sequenceFramesSent+numberOfFramesToTransfer;
                
                % Read timing
                this.sequenceTiming(framesToTransfer-bufferFrameSize) = this.getTime(startIndex, numberOfFramesToTransfer);
                
                % Set new signal points
                if (this.sequenceFramesSent < this.sequenceFramesTotal)
                    this.setConfig('stopAfterFrame', stopAfterFrame+numberOfFramesToTransfer);
                    this.setConfig('signalOnFrame', stopAfterFrame);
                else
                    this.setConfig('stopAfterFrame',this.sequenceFramesTotal);
                    this.setConfig('signalOnFrame', 0);
                end
                this.resetSignal();
                
                % Check if we were too late (buffer underrun)
                if this.getConfig('run')==false
                    warning(['The buffer could not be filled in time (after frame #' int2str(frameCounter) ').']);
                    this.setConfig('run', true);
                end
                
                % Wait for the next signal
                this.waitForSignal();
                
                % Get the frame counter after the wait
                frameCounter = this.getConfig('frameCounter');
            end
            
            % Read remaining timing
            remainingTimings = this.getTime(0, bufferFrameSize);
            indexesToCopy = max(1,this.sequenceFramesTotal-bufferFrameSize+1):this.sequenceFramesTotal;
            indexesToCopyBuffer = mod(indexesToCopy-1, bufferFrameSize)+1;
            this.sequenceTiming(indexesToCopy) = remainingTimings(indexesToCopyBuffer);
            
            % Return timings
            res = this.sequenceTiming;
            
            % Clear sequence
            this.clearSequence();
        end
        
        % getConfig - Read one or all of the configuration variables
        function res = getConfig(this, varargin)
                res = dx_fullscreen_mex('getConfig', this.objectHandle, varargin{:});
        end
        
        % setConfig - Set one of the configuration variables
        function setConfig(this, field, value)
            dx_fullscreen_mex('setConfig', this.objectHandle, field, value);
        end
        
    end
    
    
    methods (Access=private)
        % openFiles - Open the shared memory streams in C++
        function res = openFiles(this)
            res = dx_fullscreen_mex('openFiles', this.objectHandle);
        end

        % closeFiles - Close the shared memory streams in C++
        function closeFiles(this)
            dx_fullscreen_mex('closeFiles', this.objectHandle);
        end
        
        % putData - Copy data to the frame buffer
        function putData(this, startIndex, data)
            dx_fullscreen_mex('putData', this.objectHandle, int32(startIndex), data);
        end

        % getTime - Get timing data from the shared memory
        function res = getTime(this, startIndex, numberOfElements)
            res = dx_fullscreen_mex('getTime', this.objectHandle, int32(startIndex), int32(numberOfElements));
        end
        
        % waitForSignal - Wait for the signal from the C++ process
        function waitForSignal(this, timeoutMilliseconds)
            if nargin<2
                % Default timeout
                timeoutMilliseconds = 15000;
            end
            dx_fullscreen_mex('waitForSignal', this.objectHandle, int32(timeoutMilliseconds));
        end
        
        % resetSignal - Clear signal from the C++ process
        function resetSignal(this)
            dx_fullscreen_mex('resetSignal', this.objectHandle);
        end
        
        % nextFrameIndex - Shortcut for calculating the next frame index in
        %                  the buffer.
        function res = nextFrameIndex(this)
           bufferFrameIndex = this.getConfig('bufferFrameIndex');
           bufferFrameSize = this.getConfig('bufferFrameSize');
           if (bufferFrameIndex<(bufferFrameSize-1))
               res = bufferFrameIndex+1;
           else
               res = 0;
           end
        end
    end
    
    methods (Static, Access=private)
        function startup(options)
            % Find path of this script
            [path, ~, ~] = fileparts([mfilename('fullpath') '.m']);
            basePath = path;

            % Load default options
            defaults = load([path '\dx_fullscreen_defaults.mat']);
            
            % Complement input with defaults
            if nargin==0
                options = struct();
            end
            fields = fieldnames(defaults);
            for i=1:numel(fields)
                if ~isfield(options, fields{i})
                    options = setfield(options, fields{i}, defaults.(fields{i})); %#ok<SFLD>
                end
            end
            
           % Write config to an INI file
           iniPath = [path '\dx_engine_config.ini'];
           fid = fopen(iniPath,'w');
           fprintf(fid,'[dx_engine]\r\n');
           fields = fieldnames(options);
           for i=1:numel(fields)
               fprintf(fid,[fields{i} '=' num2str(options.(fields{i}))]);
               fprintf(fid,'\r\n');
           end
           fclose(fid);
           
		   % Find executable
           if (~exist([path '\dx_engine.exe'],'file'))
                path = [basePath '\..\Release'];
           end
           if (~exist([path '\dx_engine.exe'],'file'))
                error('Executable not found.');
           end
                            
           % System call
           system(['start "DirectX Fullscreen"' ' ' ...
                   '/D "' path '"' ' ' ...
                   '"' path '\dx_engine.exe' '"' ' ' ...
                   iniPath]);
               
           % Wait for startup
           timeout = tic;
           signal_state = [];
           while ~strcmpi(signal_state, 'signalled') && toc(timeout)<10
               pause(0.1);
               signal_state = dx_fullscreen_signal();
           end
           pause(0.1);
           if ~strcmpi(signal_state, 'signalled')
              error(['Fullscreen application did not start successfully. Check the error log. Last communication state: ' signal_state '.']); 
           end
        end
    end
    
    
end