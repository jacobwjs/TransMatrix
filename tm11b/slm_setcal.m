function slm_setcal(params)
    % Stores the SLM calibration in a file.
    %
    %  - Damien Loterie (08/2015)
    
    % Refresh metadata
    params.time = clock;
    params.DeviceName = 'SLM';
    params.exposure = [];
    
    % Round coordinates
    params.fiber.x  = round(params.fiber.x);
    params.fiber.y  = round(params.fiber.y);
    params.fiber.r1 = round(params.fiber.r1);
    params.fiber.r2 = round(params.fiber.r2);
    params.freq.x   = round(params.freq.x);
    params.freq.y   = round(params.freq.y);
    params.freq.r1  = round(params.freq.r1);
    params.freq.r2  = round(params.freq.r2);
    
    
    % Recalculate masks
    dims = params.ROI(3:4);
    params.fiber.mask1 = mask_circular(dims, params.fiber.x, params.fiber.y, params.fiber.r1);
    params.fiber.mask2 = mask_circular(dims, params.fiber.x, params.fiber.y, params.fiber.r2);
    params.freq.mask1  = mask_circular(dims, params.freq.x,  params.freq.y,  params.freq.r1);
    params.freq.mask2  = mask_circular(dims, params.freq.x,  params.freq.y,  params.freq.r2);
    params.freq.mask1c = mask_circular(dims, [],             [],             params.freq.r1);
    params.freq.mask2c = mask_circular(dims, [],             [],             params.freq.r2);
    
    % Save
    save('slm_cal_data.mat','params');
end

