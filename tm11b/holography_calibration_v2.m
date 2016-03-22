function [params, frame_ROI, frame] = holography_calibration_v2(varargin)
    % Function to set the ROI of the camera and calculate a mask in the
    % Fourier domain for doing off-axis holography.
    % - Damien Loterie (01/2014)
    %
    % Updated to remove some non-necessary functionality for the Meadowlark
    % SLM.
    % - Jacob Staley (02/2016)
    
    
    switch numel(varargin)
        case 1
            vid = varargin{1};
            DeviceName = vid.source.name;
            
            % Default exposure if nothing is provided.
            exposure = 30e3;
        case 2
            vid = varargin{1};
            DeviceName = vid.source.name;
            exposure = varargin{2};
%         case 3
%             img = varargin{1};
%             Fimg = varargin{2};
%             params = varargin{3};
%             DeviceName = params.DeviceName;
%             exposure = params.exposure;
        otherwise
            error('Invalid syntax');
    end
    
    
    % Get the full frame dimensions of the video source (i.e. camera).
    video_x_pixels = get(vid.source, 'WidthMax');
    video_y_pixels = get(vid.source, 'HeightMax');
 
    
    % Get a picture from the camera if there's isn't one provided already
    if ~exist('img','var')
        % Get a frame from the camera over the full sensor.
        set(vid, 'ROIPosition', [0 0 video_x_pixels video_y_pixels]);
        
        % Don't sync with the SLM.
        sync = false;
        
        if exist('params','var')
            frame = get_frame(vid, params.exposure, sync);
        else
            frame = get_frame(vid, exposure, sync);
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
    %fiber_done = false;
    %while ~fiber_done
    fiber = holography_cal_circles(img);
    
    roi_flag = true;
    if roi_flag
        % This check is because the photonfocus camera only allows
        % adjustments of multiples of 32 pixels for some strange
        % reason. 'ROI_adapt' ensures that happens.
        if isequal(get(vid.source, 'DeviceVendorName'), 'Photonfocus AG')
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
        ROI = [0 0 video_x_pixels video_y_pixels];
        xmin   = ROI(1);
        ymin   = ROI(2);
        width  = ROI(3);
        height = ROI(4);
    end
    %end
    
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
    
    % Find the center coordinates and the radius of the +1 order.
    freqdata = holography_cal_circles(Fimg);
    
    % Output parameters
    params = struct();
    params.DeviceName   = DeviceName;
    params.ROI          = ROI;
    params.exposure     = exposure;
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
    
end