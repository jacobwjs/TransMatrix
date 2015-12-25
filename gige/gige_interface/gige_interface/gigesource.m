% GIGESOURCE
% MATLAB class wrapper to an underlying C++ class for GigE acquisition
%  - Damien Loterie (11/2014)

classdef gigesource < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
    end
    
    methods        
        % Constructor
        function obj = gigesource(camera_identifier)            
            % Create class
            obj.objectHandle = gigesource_mex('new');
            
            % Attempt to initialize the acquisition system
            gigesource_mex('Initialize', obj.objectHandle, camera_identifier);
        end
        
        % Destructor
        function delete(this)
            gigesource_mex('delete', this.objectHandle);
        end
        
        % Get/Set translator
        function res = translate_getset(~,property)
           switch lower(property)
               case 'framestarttriggermode'
                   res = 'TriggerMode';
               case 'framestarttriggersource'
                   res = 'TriggerSource';
               otherwise
                   res = property;
           end
        end
        
        % Get
        function res = get(this,var)
            if nargin==1
                res = gigesource_mex('GetAll', this.objectHandle);
            elseif nargin==2
                var = this.translate_getset(var);
                res = gigesource_mex('Get', this.objectHandle, var);
            else
                error('Unexpected arguments');
            end
        end
        
        % Set
        function set(this, var, value)
            narginchk(2,3);
            var = this.translate_getset(var);
            if nargin==2
                gigesource_mex('Set', this.objectHandle, var, []);
            else
                gigesource_mex('Set', this.objectHandle, var, value);
            end
        end
        
        % Start
        function start(this)
            gigesource_mex('Start', this.objectHandle);
        end
        
        % Stop
        function stop(this)
            gigesource_mex('Stop', this.objectHandle);
        end
        
        % Get number of images
        function res = getnumberofimages(this)
           res = gigesource_mex('GetNumberOfImages', this.objectHandle);
        end
        
        % Get last image (and flush all others)
        function res = getlastimage(this)
           res = gigesource_mex('GetLastImage', this.objectHandle);
        end
        
        % Get a number of images
        function [data, time] = getimages(this, n)
            if nargout<=1
                % Only get the images
                data = gigesource_mex('GetImages', this.objectHandle, n);
            elseif nargout==2
                % Also get the timestamps
                [data, time] = gigesource_mex('GetImages', this.objectHandle, n);
                
                % Attempt converting to seconds
                try
                   time = double(time)/double(this.get('GevTimestampTickFrequency'));
                catch
                   warning('The conversion of timestamps to seconds failed. The raw timestamps were returned instead.'); 
                end
            else
                error('Unexpected number of output arguments');
            end
        end
        
        % Flush
        function flush(this)
           gigesource_mex('FlushImages', this.objectHandle);
        end
        
        % Wait
        function wait(this, timeout_seconds, n)
           gigesource_mex('WaitImages', this.objectHandle, n, timeout_seconds);
        end
        
        % Get number of errors
        function res = getnumberoferrors(this)
           res = gigesource_mex('GetNumberOfErrors', this.objectHandle);
        end
        
        % Get list of errors
        function res = geterrors(this)
           res = gigesource_mex('GetErrors', this.objectHandle);
        end
        
        %--------------------- JWJS -------------------------
        % Get the device info (MAC, IP, etc.)
        function res = getdeviceinfo(this)
            res = gigesource_mex('GetDeviceInfo', this.objectHandle);
        end
        %---------------------------


    end
end