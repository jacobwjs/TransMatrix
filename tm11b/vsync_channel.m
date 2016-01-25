function res = vsync_channel
    % ------------------------------ JWJS ------------------
    % Replacing hardcoded values for attached devices.
    %res = '/Dev1/PFI9';
    NI_daq = get(daq.getDevices());
    res = ['/', NI_daq(1).ID, '/PFI9'];
end

