function slm_params = slm_getcal_v2(varargin)
    % Throw an error if function inputs are incorrect.
    %narginchk(1, 3);
    
    slm_props = varargin{1};
    slm_params = varargin{2};
    
    % [LOAD ALIGNMENT DATA]
    % Sensor sizes
    Nx_slm = slm_props.x_pixels;
    Ny_slm = slm_props.y_pixels;
    L_pixel_slm = slm_props.pixel_size;
    
    
    % Load all alignment data
    %load('./slm_cal_data.mat','params');
    
    % Keep proximal data only
    %slm_params = params(strcmpi({params.DeviceName},'SLM')); %#ok<*NODEF>
    
    % Given the small size of the Meadowlark (i.e. 512x512 pixels) this 
    % should be the entire SLM, which can be achieved by
    % aligning the above mentioned image to the center of the SLM and
    % ensuring the radius covers to the outer edges of the SLM pixels.
    x_slm_full = round(Nx_slm/2);
    y_slm_full = round(Ny_slm/2);
    
    % [READ ROI OPTIONS]
    % Defaults
    ROI_position      = [];
    ROI_size_default  = [Nx_slm Ny_slm];
    ROI_size          = ROI_size_default;
    ROI_center        = false;
    
    
    % [SLM ROI CALCULATION]
    if isempty(ROI_position)
        ROI_position = [x_slm_full - center_of(ROI_size(1)),...
                        y_slm_full - center_of(ROI_size(2))];
    end
    ROI_old = slm_params.ROI;
    ROI_new = [round(ROI_position) ROI_size];
    
    % Checks
    ROI_clipping = -min([0,...
                         ROI_new(1),...
                         ROI_new(2),...
                         Nx_slm-(ROI_new(1)+ROI_new(3)),...
                         Ny_slm-(ROI_new(2)+ROI_new(4))]);
    if (ROI_clipping>0)
        warning(['The calculated SLM ROI is outside the SLM''s range by up to ' int2str(ROI_clipping) ' pixels.']); 
    end
    
    
    % [SPATIAL POSITION FINAL CALCULATION]
    % Fiber exact position w.r.t. SLM ROI
    x_slm_ROI = x_slm_full - ROI_new(1);
    y_slm_ROI = y_slm_full - ROI_new(2);

    % Round SLM coordinates
    x_slm_ROI_r = round(x_slm_ROI);
    y_slm_ROI_r = round(y_slm_ROI);
    
    % [FREQUENCY CALCULATION]
    % Alignment correction
    px_slm_norm = (slm_params.freq.x - center_of(slm_params.ROI(3))) / (slm_params.ROI(3) * L_pixel_slm);
    py_slm_norm = (slm_params.freq.y - center_of(slm_params.ROI(4))) / (slm_params.ROI(4) * L_pixel_slm);
    
    % Fiber position w.r.t. SLM ROI (centered on DC)
    px_slm_DC = px_slm_norm * (ROI_new(3) * L_pixel_slm);
    py_slm_DC = py_slm_norm * (ROI_new(4) * L_pixel_slm);
    
    % Fiber position w.r.t. SLM ROI
    px_slm_ROI = px_slm_DC + center_of(ROI_new(3));
    py_slm_ROI = py_slm_DC + center_of(ROI_new(4));
    
    % Rounded fiber position
    px_slm_r = round(px_slm_ROI);
    py_slm_r = round(py_slm_ROI);
    
    % [OUTPUT SLM PARAMETERS]
    % Initialize
    slm_params.ROI = ROI_new;
    slm_params.exposure = [];
    
    % Positions
    slm_params.fiber.x = x_slm_ROI_r;
    slm_params.fiber.y = y_slm_ROI_r;

    slm_params.freq.x = px_slm_r;
    slm_params.freq.y = py_slm_r;
    
    % Radii
    slm_params.freq.r1  = round(slm_params.freq.r1 * ROI_new(3)/ROI_old(3) );
    slm_params.freq.r2  = round(slm_params.freq.r2 * ROI_new(3)/ROI_old(3) );

    % Create masks
    dims = slm_params.ROI(3:4);
    slm_params.fiber.mask1 = mask_circular(dims, slm_params.fiber.x, slm_params.fiber.y, slm_params.fiber.r1);
    slm_params.fiber.mask2 = mask_circular(dims, slm_params.fiber.x, slm_params.fiber.y, slm_params.fiber.r2);
    slm_params.freq.mask1  = mask_circular(dims, slm_params.freq.x,  slm_params.freq.y,  slm_params.freq.r1);
    slm_params.freq.mask2  = mask_circular(dims, slm_params.freq.x,  slm_params.freq.y,  slm_params.freq.r2);
    slm_params.freq.mask1c = mask_circular(dims, [],             [],                     slm_params.freq.r1);
    slm_params.freq.mask2c = mask_circular(dims, [],             [],                     slm_params.freq.r2);

    % Checks
    mismatch = max([0,...
                    1+slm_params.fiber.r1 - [slm_params.fiber.x, slm_params.fiber.y],...
                    (slm_params.fiber.x+slm_params.fiber.r1) - slm_params.ROI(3), ...
                    (slm_params.fiber.y+slm_params.fiber.r1) - slm_params.ROI(4)]);
    if mismatch>0 
       warning(['The calculated SLM ROI does not fully cover the fiber''s core (mismatch: ' int2str(mismatch) ' pixels).']); 
    end
    
end