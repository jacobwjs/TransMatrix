% GIGEINPUT
% MATLAB wrapper around GIGESOURCE to provide functionalities similar to
% videoinput for GigE acquisition (but without all the bugs).
% It was written specifically for PhotonFocus MV1-D1312-100-G2-12 cameras. 
%  - Damien Loterie (11/2014)

classdef gigeinput < hgsetget
    
    properties (SetAccess = private, GetAccess = public)
        source;
        Running = false;

        VideoResolution;
        VideoFormat;
        FramesAvailable;
        TriggerType;
        Errors;
    end
    properties
        Timeout = 10;
        UserData = [];
        ROIPosition;
        TriggerRepeat;
    end
    
    methods
        % Constructor
        function vid = gigeinput(camera_identifier)
            vid.source = gigesource(camera_identifier);
            vid.Timeout = 10;
            vid.UserData = [];
        end
        
        % Destructor
        function delete(vid)
            delete(vid.source);
        end
                
        % Start
        function start(vid)
            vid.source.start();
            vid.Running = true;
        end
        
        % Stop
        function stop(vid)
            vid.source.stop();
            vid.Running = false;
            
            % Check for errors
            n_err = vid.source.getnumberoferrors();
            if n_err>0
               warning(['There are ' int2str(n_err) ' errors in the error log.']);
            end
        end
        
        % Wait
        % Note: The calling convention is different than in gigesource!
        function wait(vid, timeout_seconds, number_of_frames)
            if nargin~=3 || ~isnumeric(number_of_frames);
               error('Unexpected arguments: gigeinput.wait requires a timeout as first argument and a number of frames as second argument.');
            else
                vid.source.wait(timeout_seconds, number_of_frames);
            end
        end
        
        % GetData
        function [data, time] = getdata(vid, n)
            % Check input
            if nargin<2
               error('Unexpected arguments; the gigeinput getdata function always requires that the number of frames is specified.'); 
            end
            
            % Wait for frames
            vid.wait(vid.Timeout, n);
            
            % Get frames
            if nargout<=1
               data = vid.source.getimages(n);
            elseif nargout==2
               [data, time] = vid.source.getimages(n);
            else
               error('Unexpected number of output arguments');
            end
        end
          
        % Flush
        function flushdata(vid)
            vid.source.flush();
        end
        
        % IsRunning
        function res = isrunning(vid)
           res = vid.Running; 
        end
        
        % GetSelectedSource
        function res = getselectedsource(vid)
           res = vid.source; 
        end
        
        % GetSnapshot
        % Note: This method is not fail-safe. If an error occurs, the
        % camera might be left in a different state than before the call.
        function frame = getsnapshot(vid)
            % Check acquisition mode
            AcquisitionMode = get(vid.source, 'AcquisitionMode');
            if ~strcmpi(AcquisitionMode, 'SingleFrame') ...
                 && ~strcmp(AcquisitionMode, 'Continuous')
               error(['The current AcquisitionMode (' AcquisitionMode ') is not supported by getsnapshot.']);
            end
            
            % Start acquisition if needed
            PreviousRunState = vid.Running;
            if ~PreviousRunState
                PreviousFrames = vid.FramesAvailable;
                start(vid);
            end
            
            % Send trigger signal
            if strcmpi(get(vid.source,'TriggerMode'), 'On')
                TriggerSource = get(vid.source,'TriggerSource');
                if ~strcmpi(TriggerSource, 'Software')
                    set(vid.source,'TriggerSource','Software');
                end
                trigger(vid);
                if ~strcmpi(TriggerSource, 'Software')
                    set(vid.source,'TriggerSource',TriggerSource);
                end
            end
            
            % Wait for frame
            try
                frame = getdata(vid, 1);
            catch ex
                if ~PreviousRunState
                    stop(vid);
                end
                rethrow(ex);
            end
            
            % Stop acquisiton if needed
            if ~PreviousRunState
                % Stop acquisition
                stop(vid);
                
                % Clear extra frames
                if vid.FramesAvailable>PreviousFrames
                   getdata(vid, vid.FramesAvailable-PreviousFrames);
                end
            end
            
        end
        
        % Trigger
        function trigger(vid)
           set(vid.source,'TriggerSoftware'); 
        end
        
        % TriggerConfig
        function triggerconfig(vid,type)
            % Input check
            if nargin>2
               error('The gigeinput class does not support additional triggerconfig arguments');
            end
            
            % Cases
            switch lower(type)
                case 'immediate'
                    set(vid.source, 'TriggerMode', 'Off');
                case 'software'
                    set(vid.source, 'TriggerMode', 'On');
                    set(vid.source, 'TriggerSource', 'Software');
                case 'hardware'
                    set(vid.source, 'TriggerMode', 'On');
                    set(vid.source, 'TriggerSource', 'Line1');
                otherwise
                    error('Unsupported trigger type');
            end 
        end
        
        % Properties get/set
        function res = get.ROIPosition(vid)
            res = double(...
                  [get(vid.source,'OffsetX'),...
                   get(vid.source,'OffsetY'),...
                   get(vid.source,'Width'),...
                   get(vid.source,'Height')] ...
                   );
        end
        function set.ROIPosition(vid,ROI)
            if ~isnumeric(ROI) || ~isreal(ROI) || numel(ROI)~=4 || ~(all(ROI==round(abs(ROI))));
               error('Invalid ROI'); 
            end
           
            % Save running state of camera before ROI update.
            if (vid.Running)
                leave_camera_running = true;
            else
                leave_camera_running = false;
            end
            
            % Ensure the video source is stopped before updating, otherwise
            % it is an error.
            stop(vid);
            
            set(vid.source,'Width',ROI(3)); %#ok<MCSUP>
            set(vid.source,'Height',ROI(4)); %#ok<MCSUP>
            set(vid.source,'OffsetX',ROI(1)); %#ok<MCSUP>
            set(vid.source,'OffsetY',ROI(2)); %#ok<MCSUP>
            
            % Start camera if it was not running before, otherwise it is
            % left non-running.
            if leave_camera_running
                start(vid);
            end
            
        end
        function res = get.VideoResolution(vid)
            res = [get(vid.source,'Width'),...
                   get(vid.source,'Height')];
        end
        function res = get.VideoFormat(vid)
            res = get(vid.source,'PixelFormat');
        end
        function res = get.TriggerRepeat(~)
            res = Inf;
        end
        function set.TriggerRepeat(~, val)
            if ~isinf(val)
                error('The gigeinput class does not support TriggerRepeat. This property can only be set to Inf.');
            end
        end
        function res = get.FramesAvailable(vid)
            res = vid.source.getnumberofimages();
        end
        function res = get.Errors(vid)
            res = vid.source.getnumberoferrors();
        end
        function res = get.TriggerType(vid)
            TriggerMode = get(vid.source, 'TriggerMode');
            
            if strcmpi(TriggerMode,'Off')
                res = 'immediate';
            else
                TriggerSource = get(vid.source, 'TriggerSource');
                if strcmpi(TriggerSource,'Software')
                    res = 'software';
                else
                    res = 'hardware';
                end
            end
        end
        
        %------------------------------- JWJS --------------
        function res = getDeviceInfo(vid)
            res = vid.source.getdeviceinfo();
        end
        %-------------------------------------
    end
    
end

