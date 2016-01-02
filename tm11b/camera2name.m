function [Name, DeviceID, Counter, MAC] = camera2name(str)
    % This function converts between human readable camera names and
    % hardware device IDs. It also says which camera is connected to which
    % counter channel of the DAQ system.
    %  - Damien Loterie (10/2014)

    
    
    
    switch lower(str)
        case 'slm'
            Name     = 'SLM';
            DeviceID = 'SLM';
            Counter  = [];
            MAC      = [];
        case 'distal';
            Name     = 'proximal'
            DeviceID = '022700017637';
            Counter  = 'Dev2/ctr0'
            MAC      = '00:11:1c:f5:a1:b9'
        case 'proximal';
            Name     = 'distal'
            DeviceID = '024800016404';
            Counter  = 'Dev2/ctr0'
            MAC      = '00:11:1c:f5:a0:fe'
            
                 
        otherwise
            error('camera2name(): Unrecognized identifier.');
    end

end

