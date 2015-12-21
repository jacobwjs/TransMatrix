% DISKWRITER
% MATLAB class wrapper to an underlying C++ class for disk dump from a GigE source
%
% Note: With this class, there is potential for race conditions and access
%       violations. Once the gigesource object has been passed to the
%       diskwriter, other objects and the user are forbidden to get data
%       from the gigesource. If concurrent access to the gigesource does
%       occur, no synchronisation mechanism exists, and therefore race 
%       conditions are possible.
%       
%  - Damien Loterie (03/2015)

classdef diskwriter < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
        
        % Source object
        vid;
        source;
    end
    
    properties
        Timeout;
    end
    properties (SetAccess = private)
        FilePath;
        PassThrough;
    end
    
    methods        
        % Constructor
        function obj = diskwriter(file_path, vid, pass_through) 
            % Input processing
            if nargin<3
               pass_through = false; 
            end
            if isa(vid,'gigeinput')
               obj.vid = vid; 
            else
               error('diskwriter only works with a gigeinput'); 
            end
            obj.source = vid.source;
            obj.PassThrough = pass_through;
            obj.FilePath = file_path;
            obj.Timeout = 10;
            
            % Create class
            obj.objectHandle = diskwriter_mex('new');
            
            % Attempt to initialize the acquisition system
            diskwriter_mex('Initialize', obj.objectHandle, ...
                                         file_path, ...
                                         obj.vid.source, ...
                                         pass_through==true);
        end
        
        % Destructor
        function delete(this)
            diskwriter_mex('delete', this.objectHandle);
        end
                
        % Get
        function res = get(this, var)
            if strcmpi(var,'FramesAvailable')
                res = this.getnumberofimages;
            else
                res = get(this.vid, var);
            end
        end
        
        % Set
        function set(this, var, value)
            set(this.vid, var, value);
        end
        
        % Start
        function start(this)
            start(this.vid);
        end
        
        % Stop
        function stop(this)
            stop(this.vid);
        end
        
        % Get number of images
        function res = getnumberofimages(this)
           res = diskwriter_mex('GetNumberOfImages', this.objectHandle);
        end
        
        % Get a number of images
        function [data, time] = getimages(this, n)
            if nargout<=1
                % Only get the images
                data = diskwriter_mex('GetImages', this.objectHandle, n);
            elseif nargout==2
                % Also get the timestamps
                [data, time] = diskwriter_mex('GetImages', this.objectHandle, n);
                
                % Attempt converting to seconds
                try
                   time = double(time)/double(this.source.get('GevTimestampTickFrequency'));
                catch
                   warning('The conversion of timestamps to seconds failed. The raw timestamps were returned instead.'); 
                end
            else
                error('Unexpected number of output arguments');
            end
        end
        
        % Wait
        function wait(this, timeout_seconds, n)
            if nargin~=3 || ~isnumeric(n);
               error('Unexpected arguments: diskwriter.wait requires a timeout as first argument and a number of frames as second argument.');
            else
                diskwriter_mex('WaitImages', this.objectHandle, n, timeout_seconds);
            end
           
        end
        
        % GetData
        function [data, time] = getdata(this, n)
            % Check input
            if nargin<2
               error('Unexpected arguments; the diskwriter.getdata function always requires that the number of frames is specified.'); 
            end
            
            % Wait for frames
            this.wait(this.Timeout, n);
            
            % Get frames
            if nargout<=1
               data = this.getimages(n);
            elseif nargout==2
               [data, time] = this.getimages(n);
            else
               error('Unexpected number of output arguments');
            end
        end
        
        % Get number of errors
        function res = getnumberoferrors(this)
           res = diskwriter_mex('GetNumberOfErrors', this.objectHandle);
        end
        
        % Get list of errors
        function res = geterrors(this)
           res = diskwriter_mex('GetErrors', this.objectHandle);
        end
        
        % Flush images (and file)
        function flushdata(this)
            this.vid.flushdata;
            diskwriter_mex('FlushImages', this.objectHandle);
        end
		
    end
end