function res = saturation_level
    % This function works as a global variable, defining the saturation
    % level of the cameras we use. This is to allow rescaling to double
    % precision values from 0 to 1, or checking for overexposure.
	%  - Damien Loterie (04/2015)

    res = 2^12-1;
end

