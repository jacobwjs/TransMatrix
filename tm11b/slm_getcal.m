function slm_params = slm_getcal(varargin)
    % get the calibration parameters of the SLM.
    %
    %  - Damien Loterie (08/2015)
    %
    
    % [LOAD ALIGNMENT DATA]
    % Sensor sizes
    [Nx_slm, Ny_slm, L_pixel_slm] = slm_size();
    
    % Load all alignment data
    load('./slm_cal_data.mat','params');
    
    % Keep proximal data only
    slm_params = params(strcmpi({params.DeviceName},'SLM')); %#ok<*NODEF>
    
    % Check result
    if numel(slm_params)~=1 || ~isstruct(slm_params)
       error('Could not find the SLM parameters'); 
    end
    
%     % Check time
%     if isempty(slm_params.time) || etime(clock,slm_params.time)>4*3600
%         if isempty(slm_params.time)
%            time_str = ' '; 
%         else
%            time_str = [' (' prettytime(etime(clock,slm_params.time)) ')'];
%         end
% 
%         warning(['The alignment parameters for the SLM are outdated' time_str '.']);
% 
% %         ans_str = input('Do you still want to continue? [y/n] ','s');
% %         if ~strcmpi(ans_str, 'y')
% %             error('Operation aborted by user.'); 
% %         end
%     end


    % [SPATIAL POSITION]
    x_slm_full = slm_params.ROI(1) + slm_params.fiber.x;
    y_slm_full = slm_params.ROI(2) + slm_params.fiber.y;
    
    % [READ ROI OPTIONS]
    % Defaults
    ROI_position      = [];
    ROI_size_default  = slm_params.ROI(3:4);
    ROI_size          = ROI_size_default;
    ROI_center        = false;
    
    % Checks
    str_args = varargin(cellfun(@ischar,varargin));
    if numel(unique(str_args))<numel(str_args)
       error('Repeated options are not allowed'); 
    end
    
    % Process
    while numel(varargin)>0
        if ~ischar(varargin{1}) || isempty(varargin{1})
           error(['Invalid option: ''' varargin{1} '''']);
        end
        switch varargin{1}
            case 'ROIPosition'
                % Input processing
                if numel(varargin)<2
                   error('Missing argument'); 
                end
                data = varargin{2};
                if ~isnumeric(data) || numel(data)~=2
                   error('Invalid argument'); 
                end
                
                % Set option
                ROI_position = data([1 2]);
                
                % Pop elements
                varargin = varargin(3:end);
            case 'ROISize'
                % Input processing
                if numel(varargin)<2
                   error('Missing argument'); 
                end
                data = varargin{2};
                if ~isnumeric(data) || numel(data)~=2 || ~all(round(data)==data)
                   error('Invalid argument'); 
                end
                
                % Set option
                ROI_size = data([1 2]);
                
                % Pop elements
                varargin = varargin(3:end);
            case 'ROICenter'
                % Set option
                ROI_center = true;
                
                % Pop elements
                varargin = varargin(2:end);
                
            otherwise
                error('Invalid option');
        end
    end
    
    % Check conflicts
    if (ROI_center && ~isempty(ROI_position))
       error('Conflicting options'); 
    end
    
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

