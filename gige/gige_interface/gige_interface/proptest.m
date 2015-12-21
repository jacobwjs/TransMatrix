classdef proptest < hgsetget
    %PROPTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        refs;
        Style;
    end
    
    methods
        function obj = set(obj,prop,val)
           obj.refs = refs+1;
           disp([prop '=' val]);
        end
        
        function res = get(obj,prop)
           obj.refs = refs+1;
           disp(prop);
           res = 0; 
        end
    end
    
end

