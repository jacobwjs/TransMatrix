% FFTPROCESSOR
% MATLAB class wrapper to an underlying C++ class for real-time FFT of a GigE source
%
% Note: With this class, there is potential for race conditions and access
%       violations. Once the gigesource object has been passed to the
%       fftprocessor, other objects and the user are forbidden to get data
%       from the gigesource. If concurrent access to the gigesource does
%       occur, no synchronisation mechanism exists, and therefore race 
%       conditions are possible.
%       
%  - Damien Loterie (03/2015)

classdef fftprocessor < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
        
        % Source object
        input_obj;
        source;
    end
    
    properties
        Timeout;
    end
    properties (SetAccess = private)
        Width;
        Height;
        Indices;
    end
    
    methods        
        % Constructor
        function obj = fftprocessor(width, height, input_obj, indices) 
            % Input processing
            if isa(input_obj,'gigeinput')
               init_obj = input_obj.source;
            elseif isa(input_obj, 'diskwriter')
               init_obj = input_obj;
            else
               error('fftprocessor only works with a gigeinput or a diskwriter'); 
            end
            obj.input_obj = input_obj;
            obj.source = input_obj.source;
            obj.Width = width;
            obj.Height = height;
            obj.Indices = indices;
            obj.Timeout = 10;
            
            % Create class
            obj.objectHandle = fftprocessor_mex('new');
            
            % Attempt to initialize the acquisition system
            fftprocessor_mex('Initialize', obj.objectHandle, ...
                                         width, ...
                                         height, ...
                                         init_obj,...
                                         indices);
        end
        
        % Destructor
        function delete(this)
            fftprocessor_mex('delete', this.objectHandle);
        end
                
        % Get
        function res = get(this, var)
            if strcmpi(var,'FramesAvailable')
                res = this.getnumberofimages();
            else
                res = get(this.input_obj, var);
            end
        end
        
        % Set
        function set(this, var, value)
            set(this.input_obj, var, value);
        end
        
        % Start
        function start(this)
            start(this.input_obj);
        end
        
        % Stop
        function stop(this)
            stop(this.input_obj);
        end
        
        % Get number of images
        function res = getnumberofimages(this)
           res = fftprocessor_mex('GetNumberOfImages', this.objectHandle);
        end
        
        % Get a number of images
        function [data, time] = getimages(this, n)
            if nargout<=1
                % Only get the images
                data = fftprocessor_mex('GetImages', this.objectHandle, n);
            elseif nargout==2
                % Also get the timestamps
                [data, time] = fftprocessor_mex('GetImages', this.objectHandle, n);
                
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
               error('Unexpected arguments: fftprocessor.wait requires a timeout as first argument and a number of frames as second argument.');
            else
                fftprocessor_mex('WaitImages', this.objectHandle, n, timeout_seconds);
            end
           
        end
        
        % GetData
        function [data, time] = getdata(this, n)
            % Check input
            if nargin<2
               error('Unexpected arguments; the fftprocessor.getdata function always requires that the number of frames is specified.'); 
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
           res = fftprocessor_mex('GetNumberOfErrors', this.objectHandle);
        end
        
        % Get list of errors
        function res = geterrors(this)
           res = fftprocessor_mex('GetErrors', this.objectHandle);
        end
        
        % Flush images (and file)
        function flushdata(this)
            this.input_obj.flushdata;
            fftprocessor_mex('FlushImages', this.objectHandle);
        end
		
    end
end