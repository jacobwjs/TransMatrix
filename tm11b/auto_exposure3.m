function [exposure_value, frame] = auto_exposure3(vid, starting_value, target_tol, target_level, sync)
    % Automatically sets the exposure of the input video object.
    % Can be synchronized with the SLM.
    % - Damien Loterie (01/2014)
    
    
    % Input check
    source = get(vid,'source');
    DeviceID = get(source,'DeviceID');
    ROI = vid.ROIPosition;
    if nargin<2 || isempty(starting_value)
       starting_value = get(source,'ExposureTime'); 
       if starting_value==0
           starting_value=100;
       end
    end
    
    % Tuning parameters
    if nargin<3 || isempty(target_tol)
        target_tol       = 0.05;
    end
    if nargin<4 || isempty(target_level)
        target_level = 0.90 - target_tol;
    end
    if nargin<5 || isempty(sync)
        sync = true;
    end
    factor           = 2;
    show_figure      = false;
    closeness_limit  = 0.01;
    
    % Persistent figure window
    persistent h_fig;
    
    % Don't overwrite a previous figure window
    h_prev = [];
    if ~isempty(findall(0,'Type','Figure')) && show_figure
       h_prev = gcf;
    end
                             
    % Check camera configuration
    if ~strcmpi(vid.TriggerType,'hardware') ...
        || ~strcmpi(get(source,'FrameStartTriggerMode'), 'On') ...
        || ~strcmpi(get(source,'FrameStartTriggerSource'), 'Line1') ...
        || ~strcmpi(get(source,'ExposureMode'), 'TriggerWidth')
    
        error('Video source is incorrectly configured.');
    end
    flushdata(vid);
    vid.TriggerRepeat = Inf;
    
    % Start camera if needed
    if isrunning(vid)
        leave_camera_running = true;
    else
        leave_camera_running = false;
        start(vid);
    end

    % Function for getting a snapshot directly in double format
    last_snapshot = [];
    previous_levels = [];
    previous_exposures = [];
    function [lvl, exposure] = evaluate_exposure(exposure)
        % Check exposure
        if (exposure<10)
            %stop(vid);
            warning('Exposure too low'); 
            exposure = 10;
        elseif (exposure>500000)
            stop(vid);
            error('Exposure too high');
        end
        
        % Check ROI
        if not(all(ROI==vid.ROIPosition))
            warning('Correcting ROI');
            stop(vid);
            flushdata(vid);
            vid.ROIPosition = ROI;
            start(vid);
            pause(1.000);
        end
        
        % Take picture
        if sync
            triggere(DeviceID, exposure, [], 1, true);
        else
            triggere(DeviceID, exposure);
        end
        pause(0.010);
        last_snapshot = getdata(vid,1);
        
        % Calculate max
        lvl = double(max(max(last_snapshot)))/saturation_level;
        
        % Remember settings
        previous_levels(end+1) = lvl;
        previous_exposures(end+1) = exposure;
    end

    % Function for displaying a figure
    function showfig
        if show_figure
            if isempty(h_fig) || ~ishandle(h_fig)
                h_fig = figure;
            end
            
            clf(h_fig);
            subplot(1,2,1);
            hold on;
            plot(previous_exposures, previous_levels, 'b*');
            plot(lower_exposure, lower_level, 'r^');
            plot(upper_exposure, upper_level, 'rv');
            v = axis;
            v(1) = min(v(1),0);
            v(2) = max(v(2),1000);
            v(3) = 0;
            v(4) = 1;
            axis(v);
            plot([0, v(2)], (target_level-target_tol)*[1, 1],'k--');
            plot([0, v(2)], (target_level+target_tol)*[1, 1],'k--');
            hold off;
            title('Auto-exposure routine');
            
            subplot(1,2,2);
            data = last_snapshot;
            data_extra = data;
            data_extra(data>=saturation_level) = 0;
            data = cat(3,data,data_extra,data_extra);
            image(double(data)/saturation_level);
            axis image; axis off;

            pause(0.025);
        end
    end

    % First attempt
    [level, exposure_value] = evaluate_exposure(starting_value);
    
    % Prepare values for the midpoint algorithm
    if (level<target_level)
           lower_exposure = exposure_value;
           lower_level = level;
           lower_frame = last_snapshot;
           
           upper_exposure = [];
           upper_level = [];
           upper_frame = [];
    else
           lower_exposure = [];
           lower_level = [];
           lower_frame = [];
        
           upper_exposure = exposure_value;
           upper_level = level;
           upper_frame = last_snapshot;
    end

    % Iterate if needed
    iteration_limit = 50;
    i = 1;
    while ~any(abs([lower_level upper_level] - target_level) <= target_tol) ...
          && (i<iteration_limit)
            
        % Determine which new exposure value to try
        if isempty(lower_level)
            exposure_value = upper_exposure * min(1/factor, target_level/upper_level);
        elseif isempty(upper_level)
            exposure_value = lower_exposure * max(factor,   target_level/lower_level);
        else
            exposure_value = (lower_exposure + upper_exposure)/2;
        end
        
        % Try this exposure
        [level, exposure_value] = evaluate_exposure(exposure_value);

        % Use the result either as a new upper or lower bound
        if (level<target_level)
           lower_exposure = exposure_value;
           lower_level = level;
           lower_frame = last_snapshot;
        else
           upper_exposure = exposure_value;
           upper_level = level;
           upper_frame = last_snapshot;
        end
        
        % If the bounds get too close and there's no convergence, go back
        % to the first step (look for new bounds).
        if ~isempty(upper_level) && ~isempty(lower_level) ...
                && abs(upper_level/lower_level-1)<=closeness_limit
            
            if (level<target_level)
               upper_exposure = [];
            else
               lower_exposure = [];
            end
        end
            
        % Figure
        showfig;
        
        % Check if the lower limit of exposure is reached
        if numel(previous_exposures)>=2 ...
                && previous_exposures(end)==previous_exposures(end-1)
            upper_frame = last_snapshot;
            lower_frame = last_snapshot;
            upper_exposure = previous_exposures(end);
            lower_exposure = previous_exposures(end);
            break;
        end

        i = i+1;
    end

    % Check if we converged or not
    if (i==iteration_limit)
       warning('Auto-exposure: iteration limit reached.'); 
    end

    % Return the right parameters
    if (abs(upper_level-target_level)<=target_tol)
        exposure_value = upper_exposure;
        frame = upper_frame;
    else
        exposure_value = lower_exposure;
        frame = lower_frame;
    end
    
    % Stop camera
    if ~leave_camera_running
        stop(vid);
    end
    
    % Close figure if it's still open
    if ishandle(h_fig)
        close(h_fig);
        h_fig = [];
        if ~isempty(h_prev) && show_figure
            figure(h_prev);
        end
    end
   
end

