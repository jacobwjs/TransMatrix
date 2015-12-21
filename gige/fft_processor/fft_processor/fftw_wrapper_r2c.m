% fftw_wrapper_r2c - MATLAB interface to the C++ class of the same name.
%
%  - Damien Loterie (03/2015)

classdef fftw_wrapper_r2c < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
    end
    
    methods        
        % Constructor
        function obj = fftw_wrapper_r2c(width, height)             
            % Create class
            obj.objectHandle = fftw_wrapper_r2c_mex('new');
            
            % Attempt to initialize the acquisition system
            fftw_wrapper_r2c_mex('Initialize', obj.objectHandle, width, height);
        end
        
        % Destructor
        function delete(this)
            fftw_wrapper_r2c_mex('delete', this.objectHandle);
        end
                
        % Get number of images
        function res = transform(this,arr)
           res = fftw_wrapper_r2c_mex('Transform', this.objectHandle, arr);
        end

		
    end
end