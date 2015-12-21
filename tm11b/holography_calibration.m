function [params, frame_ROI, frame] = holography_calibration(varargin)
    % Function to set the ROI of the camera and calculate a mask in the
    % Fourier domain for doing off-axis holography.
    % - Damien Loterie (01/2014)

    % Camera dimensions
    [xcam, ycam] = camera_size();
    
    % Input processing
    if (ischar(varargin{end}) && strcmpi(varargin{end},'no save'))
        save_flag = false;
        varargin = varargin(1:(end-1));
    else
        save_flag = true;
    end
    if (ischar(varargin{end}) && strcmpi(varargin{end},'no ROI'))
        roi_flag = false;
        varargin = varargin(1:(end-1));
    else
        roi_flag = true;
    end
    switch numel(varargin)
        case 1
            vid = varargin{1};
            DeviceName = camera2name(get(vid.source,'DeviceID'));
        case 3
            img = varargin{1};
            Fimg = varargin{2};
            params = varargin{3};
            DeviceName = params.DeviceName;
            exposure = params.exposure;
        otherwise
            error('Invalid syntax');
    end

    % Load previous parameters if possible
    data_file = './holography_cal_data.mat';
    if exist(data_file,'file')
       % Load all previous parameters
       saved_params = load(data_file,'params');
       saved_params = saved_params.params;
       
       % Load previous parameters for this camera, if needed
       match = strcmp({saved_params.DeviceName},DeviceName);
       if any(match) && ~exist('params','var')
          params = saved_params(match); 
       end
    end

    % Get a picture from the camera if there's isn't one provided already
    if ~exist('img','var')
        % Get a correctly exposed snapshot
        set(vid,'ROIPosition',[0 0 xcam ycam]);
        if exist('params','var')
            [exposure, frame] = auto_exposure(vid, params.exposure);
        else
            [exposure, frame] = auto_exposure(vid);
        end

        % Filter frame
        img = double(frame)/saturation_level;
        mask_hp   = ~mask_circular(size(img),[],[],200);
        [X,Y] = meshgrid(1:size(img,2),1:size(img,1));
        mask_diag = X<Y;
        img = abs(ifft2(ifftshift2(fftshift2(fft2(img)).*(mask_diag & mask_hp))));
    end
    
    % Adjust levels of frame
    img_levels = quantile(img(:), [0.05,0.99]);
    img = (img-img_levels(1))/(img_levels(2)-img_levels(1));
    img(img>1) = 1;
    img(img<0) = 0;
    img = repmat(img,[1 1 3]);
    
    % Select ROI, with option to retry if it is too big
    fiber_done = false;
    while ~fiber_done
        % Identify position of the fiber
        if exist('fiber','var')
            fiber = holography_cal_circles(img, fiber.xc,...
                                                fiber.yc,...
                                                fiber.r1,...
                                                fiber.r2);
        elseif exist('params','var')
            fiber = holography_cal_circles(img, params.fiber.x+params.ROI(1),...
                                                params.fiber.y+params.ROI(2),...
                                                params.fiber.r1,...
                                                params.fiber.r2);
        else
            fiber = holography_cal_circles(img);
        end

        
        % Adapt ROI (this code is dependent on the camera)
        if roi_flag
            if isfield(params,'DeviceName') && ~strcmpi(params.DeviceName,'SLM')
                ROI = ROI_adapt(fiber.xc, fiber.yc, 2*fiber.r2);
                xmin   = ROI(1);
                ymin   = ROI(2);
                width  = ROI(3);
                height = ROI(4);
            else
                xmin   = round(fiber.xc-fiber.r2)-1;
                ymin   = round(fiber.yc-fiber.r2)-1;
                width  = round(2*fiber.r2);
                height = round(2*fiber.r2);
                ROI = [xmin ymin width height];
            end
        else
           ROI = [0 0 xcam ycam]; 
           xmin   = ROI(1);
           ymin   = ROI(2);
           width  = ROI(3);
           height = ROI(4);
        end

        % Check if ROI has changed
        if exist('params','var') && ...
            (ROI(3)~=params.ROI(3) || ROI(4)~=params.ROI(4))

           button = questdlg(['Change ROI from ' ...
                               int2str(params.ROI(3)) 'x' int2str(params.ROI(4)) ...
                               ' to ' int2str(ROI(3)) 'x' int2str(ROI(4)) '?'],...
                              'Change ROI');
           switch button
               case 'Yes'
                   fiber_done = true;
               case 'No';
                   fiber_done = false;
               otherwise
                   error('Operation terminated by user.');
           end
        else
            fiber_done = true;
        end
    end
    
    % Save the position of the fiber inside the ROI
    fiber.xc_ROI = fiber.xc - xmin;
    fiber.yc_ROI = fiber.yc - ymin;

    % Frequency domain image
    if ~exist('Fimg','var')
        % Cut out the ROI from the frame
        frame_ROI = ROI_apply(frame, ROI);
        
        % Create frequency domain image
        F = db(fftshift(fft2(double(frame_ROI))/(numel(frame_ROI)*saturation_level)));
        Fimg = (F+100)/60;
        Fimg(Fimg>1) = 1;
        Fimg(Fimg<0) = 0;
        Fimg = ind2rgb(1+round(Fimg*255),labview);
    else
        Fimg = imresize(Fimg, [ROI(4) ROI(3)]);
        Fimg = rescale(Fimg);
        Fimg = ind2rgb(1+round(255*Fimg),labview(256));
    end
    
    if exist('params','var')
        % Rescale default parameters in case the ROI has changed
        p_old = [params.freq.x, params.freq.y];
        r_old = [params.freq.r1, params.freq.r2];
        ROI_old = params.ROI(3:4);
        ROI0_old = center_of(ROI_old);
        dp_old = p_old - ROI0_old;
        ROI0 = center_of(ROI(3:4));
        dp = dp_old./ROI_old.*ROI(3:4);
        p = ROI0 + dp;
        r = r_old .* ROI(3)./ROI_old(1);
        
        % Find region
        freqdata = holography_cal_circles(Fimg,p(1),p(2),r(1),r(2));
    else
        freqdata = holography_cal_circles(Fimg);
    end
        
    % Output parameters
    params = struct();
    params.DeviceName = DeviceName;
    params.ROI = ROI;
    params.exposure = exposure;
    params.fiber.x      = fiber.xc_ROI;
    params.fiber.y      = fiber.yc_ROI;
    params.fiber.r1     = fiber.r1;
    params.fiber.r2     = fiber.r2;
    params.freq.x       = freqdata.xc;
    params.freq.y       = freqdata.yc;
    params.freq.r1      = freqdata.r1;
    params.freq.r2      = freqdata.r2;
    params.time         = clock;
    
    % Masks
    dims = [height, width];
    params.fiber.mask1 = mask_circular(dims, params.fiber.x, params.fiber.y, params.fiber.r1);
    params.fiber.mask2 = mask_circular(dims, params.fiber.x, params.fiber.y, params.fiber.r2);
    params.freq.mask1  = mask_circular(dims, params.freq.x,  params.freq.y,  params.freq.r1);
    params.freq.mask2  = mask_circular(dims, params.freq.x,  params.freq.y,  params.freq.r2);
    params.freq.mask1c = mask_circular(dims, [],             [],             params.freq.r1);
    params.freq.mask2c = mask_circular(dims, [],             [],             params.freq.r2);
    
    % Apply ROI
    if exist('vid','var')
        set(vid,'ROIPosition',params.ROI);
    end
    
    % Save parameters
    if save_flag
        if exist(data_file,'file')
           params = [params saved_params(~match)];
        end
        save(data_file,'params'); 
    end

    % Return
    params = params(1);
end

