% fftw_wrapper_c2c - MATLAB interface to the C++ class of the same name.
%
%  - Damien Loterie (04/2015)

classdef fftw_wrapper_c2c < hgsetget
    
    properties (SetAccess = private, Hidden = true, Transient = true)
         % Handle to the underlying C++ class instance
        objectHandle;
    end
    
    methods        
        % Constructor
        function obj = fftw_wrapper_c2c(width, height)             
            % Create class
            obj.objectHandle = fftw_wrapper_c2c_mex('new');
            
            % Attempt to initialize the acquisition system
            fftw_wrapper_c2c_mex('Initialize', obj.objectHandle, width, height);
        end
        
        % Destructor
        function delete(this)
            fftw_wrapper_c2c_mex('delete', this.objectHandle);
        end
                
        % Get image
        function res = transform(this,arr)
           res = fftw_wrapper_c2c_mex('Transform', this.objectHandle, arr);
        end
        
        % Gerchberg-Saxton
        function res = gerchberg_saxton(this, data, ind, iter)
           res = fftw_wrapper_c2c_mex('GerchbergSaxton', this.objectHandle, data, ind, iter);
        end

		
    end
end