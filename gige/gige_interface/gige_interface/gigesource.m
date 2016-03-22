% GIGESOURCE
% MATLAB class wrapper to an underlying C++ class for GigE acquisition
%  - Damien Loterie (11/2014)

classdef gigesource < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
    end
    % ------------------------------- JWJS ---------------------
    properties (SetAccess = private, GetAccess = public)
        deviceInfo  = [];
        name        = [];
    end
    % --------------------------------------
    
    methods        
        % Constructor
        function obj = gigesource(camera_identifier)            
            % Create class
            obj.objectHandle = gigesource_mex('new');
            
            % --------------------- JWJS -----------------------
            obj.name = camera_identifier;
            
            % Present the user with a list of connected devices
            % that can be used for acquiring images.
            gigesource_mex('SelectDevice', obj.objectHandle);
            
            % Retrieve the selected device's information(MAC, IP, etc.)
            obj.deviceInfo = getdeviceinfo(obj);
            
            % Assign the MAC address of the selected device for
            % initialization below.
            %MAC_address = deviceInfo.MAC{1};
            
            % Attempt to initialize the acquisition system.
            % NOTE:
            % - The device has already been selected from the call to
            % 'SelectDevice', which means the 'lDeviceInfo' has already
            % been set in the C++ side. Therefore we don't need to search
            % the device, so we pass in an empty string as the last
            % argument.
            gigesource_mex('Initialize', obj.objectHandle, '');
            % ---------------------------
        end
        
        % Destructor
        function delete(this)
            display(['Releasing video source...']);
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
            info = gigesource_mex('GetDeviceInfo', this.objectHandle);
            res.IP    = char(info(1)); % IP address.
            res.model = char(info(2)); % Model name of the device.
            res.ID    = char(info(3)); % Device ID (i.e. serial number).
            res.MAC   = char(info(4)); % MAC address of the device.
        end
        %---------------------------


    end
end