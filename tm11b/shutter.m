function shutter(name, state)
	%  - Damien Loterie (09/2014)

    % Parameter validation
    if nargin<2 && strcmp(name,'reset')
        shutter('both','reset');
        return;
    end
    
    switch lower(name)
        case {'slm','proximal'}
            name = 'proximal';
        case {'distal'}
            name = 'distal';
        case 'both'
            name = 'both';
        case 1
            name = 'proximal';
        case 2
            name = 'distal';
        otherwise
            error('Invalid shutter name');
    end
    
    switch state
        case true  
        case 'on'
            state = true;
        case 'block'
            state = true;
        case 'close'
            state = true;
            
        case false    
        case 'off'
            state = false;
        case 'pass'
            state = false;
        case 'open'
            state = false;
        case 'reset'
            state = false;   
            
        otherwise
            error('Invalid state');
    end
    
%     % Manual version (temporary for LO)
%     if state==true
%         str_manual = 'block'; 
%     else
%         str_manual = 'unblock';
%     end
%     if strcmpi(name,'both')
%         name = 'all beams'; 
%     else
%         name = ['the ' name ' reference beam'];
%     end
%     disp(['Please ' str_manual ' ' name ', and then press any key.']);
%     pause
    
    % Open session
    deviceID = 'Dev1';
    s = daq.createSession('ni');

    % Open channels
    warning('off','daq:Session:onDemandOnlyChannelsAdded');
    if strcmpi(name,'proximal') || strcmpi(name,'both')
        s.addDigitalChannel(deviceID,'Port1/Line0','OutputOnly');
    end
    if strcmpi(name,'distal') ||  strcmpi(name,'both')
        s.addDigitalChannel(deviceID,'Port1/Line2','OutputOnly');
    end
    warning('on','daq:Session:onDemandOnlyChannelsAdded');

    % Send values
    if ~strcmpi(name,'Both')
        s.outputSingleScan(state);
    else
        s.outputSingleScan([state state]);
    end
    
    % Wait for the shutter to move
    pause(0.5);

    % Leave
    s.release;   
           
end

