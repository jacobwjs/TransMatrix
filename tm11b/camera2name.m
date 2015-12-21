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
        case 'proximal';
            Name     = 'proximal';
            DeviceID = '022700017637';
            Counter  = 'Dev1/ctr0';
            MAC      = '00:11:1c:f5:a1:b9';
        case 'distal';
            Name     = 'distal';
            DeviceID = '024800016404';
            Counter = 'Dev1/ctr0';
            MAC      = '00:11:1c:f5:a0:fe';
            
        case '022700017637'; % This is the proximal-side camera
            [Name, DeviceID, Counter, MAC] = camera2name('proximal');
        case '024800016404'; % This is the distal-side camera
            [Name, DeviceID, Counter, MAC] = camera2name('distal');
            
        case '1';
            [Name, DeviceID, Counter, MAC] = camera2name('proximal');
        case '2';
            [Name, DeviceID, Counter, MAC] = camera2name('distal');
            
        case 1;
            [Name, DeviceID, Counter, MAC] = camera2name('proximal');
        case 2;
            [Name, DeviceID, Counter, MAC] = camera2name('distal');
            
        otherwise
            error('Unrecognized identifier.');
    end

end

