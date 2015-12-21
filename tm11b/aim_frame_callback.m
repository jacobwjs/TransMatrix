function aim_frame_callback(vid, event)
	%   - Damien Loterie (06/2014)

    % Abort if busy
%     set(vid,'FramesAcquiredFcn', []);
%     if (UserData.busy)
%         return;
%     else
%         UserData.busy = true;
%         set(vid,'UserData',UserData);
%     end

    % Get data
    timestamp = event.Data.AbsTime;
    UserData = get(vid,'UserData');
    vid.wait(1,3);
    frame = vid.source.getlastimage();
% 	frame = getdata(vid,1);
%     flushdata(vid);
    data = double(frame)/saturation_level;
    h_img = UserData.h_img;
    
    % Calculate range
    sorted = sort(frame(:));
    low = sorted(min(1000,end));
    high = sorted(max(1,end-10));
    overexposed = sum(frame(:)==saturation_level);
    
    % Show image
    if (UserData.Fourier == false)    
        if (UserData.AutoContrast) && (high~=low) 
            % Linear contrast enhancement
            a = 1/double(high-low);
            b = -double(low)*a;
            data = (a*saturation_level)*data+b;
            data(data>1) = 1;
            data(data<0) = 0;
        end
        
        % Add red for overexposed pixels
        data_extra = data;
        data_extra(frame==saturation_level) = 0;
        data = cat(3,data,data_extra,data_extra);

        % Add green crosshair
        if (UserData.ShowCross)
            data(UserData.yr, UserData.xs,2) = 1;
            data(UserData.ys, UserData.xr,2) = 1;
            data(UserData.yr, UserData.xs,[1 3]) = 0;
            data(UserData.ys, UserData.xr,[1 3]) = 0;
        end
        
        % Add grid
        if (UserData.ShowGrid)
            data(UserData.grid_ind) = 1;
        end
        
        % Set image data
        set(h_img, 'CData', data);
    else
        % Fourier
        A = db(fftshift(fft2(data)/numel(data)));
        %set(h_img, 'CData', A);
        
        % Color data
        db_min = -100;
        db_max = db_min+60;
        A = (A-db_min)/(db_max-db_min);
        A(A<0) = 0;
        A(A>1) = 1;
        A = ind2rgb(round(1+255*A),labview(256));
        
        % Add grid
        if (UserData.ShowGrid)
            A(UserData.gridf_ind) = 1;
        end
        
        % Set image data
        set(h_img, 'CData', A);
    end
    
    % Range calculation
    if (UserData.RangeMinMax)
       range_low = sorted(1);
       range_high = sorted(end);
       range_str = 'min/max';
    else
       range_low = low;
       range_high = high;
       range_str = '99%';
    end
    
    % Get previous timestamp
    h_fig = UserData.h_fig;
    UserData_fig = get(h_fig, 'UserData');
    previous_timestamp = UserData_fig.last_update;
    
    % Estimate framerate
    if ~isempty(previous_timestamp)
        fps = 1/etime(timestamp, previous_timestamp);
    else
        fps = 0;
    end
    
    % Update text
    ExposureTime = UserData.Counter.HighTime*1e6;
    text_cell = {['Exposure time: ' num2str(ExposureTime) 'µs'],...
                 ['Range (' range_str '): [' num2str(range_low) '; ' num2str(range_high) ']'],...
                 ['Overexposed pixels: ' num2str(overexposed)],...
                 [datestr(timestamp, 'HH:MM:SS.FFF') ' (' num2str(fps,2) 'fps)']};
    set(UserData.h_txt,'String',text_cell);
    
    % Update timestamp
    UserData_fig.last_update = timestamp;
    
    % Save frane
    UserData_fig.frame = frame;
    set(h_fig, 'UserData', UserData_fig);
    
%     % Restore
%     set(vid,'FramesAcquiredFcn', @aim_frame_callback);
end

