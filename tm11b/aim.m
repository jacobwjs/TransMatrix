function aim(cam)
    % AIM
    %
    % Connects to the PhotonFocus camera and displays a live preview.
    %
    % You can use the following keys:
    %   '+': Increase exposure time
    %   '-': Decrease exposure time
    %   's': Take snapshot (saved in the folder ./data/)
    %   'c': Auto contrast enhancement
    %   't': Display/hide target
    %   'f': Fourier domain
    %   'ESC': Quit
    %
    %  - Damien Loterie (05/2014)
    
    % Parameter
    if nargin<1
        error('Choose a camera');
    else
        if isa(cam,'gigeinput') || isa(cam,'videoinput')
            vid = cam;
        else
            vid = camera_mex(cam);
        end
    end
        
    % Initialize
    source = getselectedsource(vid);
    ROI = get(vid, 'ROIPosition');
    x = ROI(3);
    y = ROI(4);

    % Auto-expose
    Exposure = auto_exposure(vid);
    Exposure = min(Exposure,100000);
    
    % Generate pulses
    HighTime = Exposure/1e6;
    Divider = 3;
    InitialDelayFunction = @(HighTime)max(20e-9,(Divider-1)/vsync_rate + vsync_delay - HighTime/2);
    InitialDelay = InitialDelayFunction(HighTime);
    LowTime = 20e-9;
	[~,~,CounterName] = camera2name(get(source,'DeviceID'));
    
    ctr = DAQmxCounterOutput(CounterName, ...
                             HighTime, ...
                             LowTime, ...
                             InitialDelay);
    ctr.CfgDigEdgeStartTrig(vsync_channel, 'falling');
    ctr.CfgImplicitTiming('finite', 1);
    ctr.EnableInitialDelayOnRetrigger = true;
    ctr.StartTriggerRetriggerable = true;
    ctr.start();

    % Figure
    h_fig = figure('Toolbar','none',...
                   'Menubar','none',...
                   'Visible', 'on', ...
                   'NumberTitle', 'off',...
                   'Color',[0 0 0]);
    set(h_fig,'Name','Live video');
    colormap(gray(256));

    % Set user data and callbacks for figure
    UserData_fig = struct();
    UserData_fig.vid = vid;
    UserData_fig.stop = 0;
    UserData_fig.last_update = [];
    UserData_fig.ctr = ctr;
    set(h_fig, 'KeyPressFcn', @aim_key_callback)
    set(h_fig, 'CloseRequestFcn', @aim_close_callback)
    set(h_fig, 'UserData', UserData_fig);

    % Image
    h_img = image(zeros(y,x));
    axis off
    axis image
    truesize(h_fig,round([y,x]/2));

    % Colorbar
    h_ax = get(h_fig, 'CurrentAxes');
    
    % Text box
    h_txt = text(1,1,'Initializing',...
                     'HorizontalAlignment','Left',...
                     'VerticalAlignment','Top',...
                     'BackgroundColor',[0 0 0],...
                     'EdgeColor',[1 1 1],...
                     'Color',[1 1 1]);

    % Margins
    set(h_fig,'Units','Normalized');
    set(h_ax,'Position',[0 0 1 1]);
    
    % Maximize figure using Java (from MATLAB File Exchange -  Oliver Woodford)
    drawnow % Required to avoid Java errors
    jFig = get(handle(h_fig), 'JavaFrame'); 
    jFig.setMaximized(true);
    
    % Generate crosshair data
    xc = (x+1)/2;
    yc = (y+1)/2;
    inner_size = 5;
    outer_size = 50;
    if (mod(x,2)==0)
       xr = x/2 + [0 1];
    else
       xr = (x+1)/2 + [-1 0 1];
    end
    if (mod(y,2)==0)
       yr = y/2 + [0 1];
    else
       yr = (y+1)/2 + [-1 0 1];
    end
    xa = (1:x);
    ya = (1:y);
    xs = abs(xa-xc)>=inner_size & abs(xa-xc)<=outer_size;
    ys = abs(ya-yc)>=inner_size & abs(ya-yc)<=outer_size;
    
    % Generate grid data, spatial domain
    grid_mask = false(y,x);
%     xg = sort(656+[-272-32*(0:11), +272+32*(0:11)]);
%     yg = sort(540+[-272-32*(0:8), +272+32*(0:8)]);
%     for i=1:numel(xg)
%        grid_mask(:,xg(i)) = true; 
%     end
%     for i=1:numel(yg)
%        grid_mask(yg(i),:) = true; 
%     end
    grid_mask = grid_mask | imdilate(bwperim(mask_circular([y,x],[],[],383)),strel('disk',1));
    grid_mask = cat(3,false(y,x),false(y,x),grid_mask);
    grid_ind = find(grid_mask);
    
    % Generate grid data, frequency domain
	[xf0,yf0] = center_of(x,y);
    xgf = round(xf0+(x/4)*[1,-1]);
    ygf = round(yf0+(y/4)*[1,-1]);
    gridf_mask = false(y,x);
    for i=1:numel(xgf)
       gridf_mask(:,xgf(i)) = true; 
    end
    for i=1:numel(ygf)
       gridf_mask(ygf(i),:) = true; 
    end
    gridf_mask(743,:) = true;
    gridf_mask(:,227) = true;
    gridf_mask = cat(3,gridf_mask,gridf_mask,gridf_mask);
    gridf_ind = find(gridf_mask);
    
%     % Draw ellipse (debug)
%     h_r1 = rectangle('Position',  [211,794,157,130],...
%                      'Curvature', [1,1],...
%                      'EdgeColor', 'r',...
%                      'LineWidth', 2);
%     h_r2 = rectangle('Position',  [260,748,145,127],...
%                      'Curvature', [1,1],...
%                      'EdgeColor', 'm',...
%                      'LineWidth', 2);
%     set(h_r1,'Visible','off');
%     set(h_r2,'Visible','off');

    % Set user data for videoinput object
    UserData = struct();
    UserData.h_fig = h_fig;
    UserData.h_img = h_img;
    UserData.h_ax = h_ax;
    UserData.h_txt = h_txt;
%     UserData.h_r1 = h_r1;
%     UserData.h_r2 = h_r2;
    UserData.xs = xs;
    UserData.xr = xr;
    UserData.ys = ys;
    UserData.yr = yr;
    UserData.xc = xc;
    UserData.yc = yc;
    UserData.grid_ind = grid_ind;
    UserData.gridf_ind = gridf_ind;
    UserData.Fourier = false;
    UserData.AutoContrast = false;
    UserData.ShowCross = true;
    UserData.RangeMinMax = false;
    UserData.ShowGrid = false;
    UserData.Counter = ctr;
    UserData.InitialDelayFunction = InitialDelayFunction;
    UserData.busy = false;
    set(vid, 'UserData', UserData);
    
%     % Set frame update function
%     set(vid,'FramesAcquiredFcn', @aim_frame_callback);
%     set(vid,'FramesAcquiredFcnCount', 1);

    % Start preview
    fig_stop = @()getfield(get(h_fig,'UserData'),'stop');
    start(vid);
    while ishandle(h_fig) ...
            && fig_stop()==0 ...
        
        % Handle frame
        aim_frame_callback(vid, struct('Data',struct('AbsTime',clock)));
        
        % Wait
        pause(0.001);
    end
    
    
    % Close
    if ishandle(h_fig) && getfield(get(h_fig,'UserData'),'stop')~=2
        close(h_fig);
    end
    if isvalid(ctr)
        ctr.stop();
        delete(ctr);
    end
    if isvalid(vid)
        stop(vid);
        %delete(vid);
    end

end

