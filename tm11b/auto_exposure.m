function [exposure_value, frame] = auto_exposure(vid, varargin)
    % Gateway function that uses the software-triggered or
    % hardware-triggered auto-exposure routine, depending on the
    % configuration of vid.
    %  - Damien Loterie (02/2014)
    
    if strcmp(get(vid,'TriggerType'),'hardware')
        [exposure_value, frame] = auto_exposure3(vid, varargin{:});
    else
        error('Auto-exposure without electronic triggering is no longer supported (06/2014).');
    end

end
