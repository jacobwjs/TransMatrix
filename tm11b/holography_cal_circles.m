function params = holography_cal_circles(img,xc,yc,r1,r2)
    % Function to help determine the fiber's location in the spatial
    % domain, and the conjugate field's position in the Fourier domain.
    % - Damien Loterie (07/2014)

    % Input parameters
    UserData = struct();
    UserData.img = img;
    UserData.y = size(img,1);
    UserData.x = size(img,2);
    UserData.done = false;
    UserData.abort = false;
    if nargin<2
       UserData.xc = center_of(UserData.x);
    else
       UserData.xc = xc;
    end
    if nargin<3
       UserData.yc = center_of(UserData.y);
    else
       UserData.yc = yc;
    end
    if nargin<4
       UserData.r1 = 100;
    else
       UserData.r1 = r1;
    end
    if nargin<5
       UserData.r2 = 120;
    else
       UserData.r2 = r2;
    end
    
    % Figure
    h_fig = figure('Toolbar','none',...
                   'Menubar','none',...
                   'Visible', 'on', ...
                   'NumberTitle', 'off',...
                   'Color',[0 0 0],...
				   'Units','Normalized');
    colormap gray(256);
    set(h_fig, 'KeyPressFcn', @holography_cal_key)
    
    % Maximize figure using Java (from MATLAB File Exchange -  Oliver Woodford)
    drawnow % Required to avoid Java errors
    jFig = get(handle(h_fig), 'JavaFrame'); 
    jFig.setMaximized(true);
    
    % Image
    UserData.h_img = image(img);
    set(gca,'Position',[0 0 1 1]);
    axis off
    axis image
    
    % Pass data to figure
    set(h_fig, 'UserData', UserData);
    
    % First update
    holography_cal_key(h_fig, struct('Key','update'));
    
    % Wait for user interaction
    while (~UserData.done) && ishandle(h_fig)
       UserData = get(h_fig,'UserData');
       pause(0.020);
    end
    if (ishandle(h_fig))
        close(h_fig);
    end
    
    % Quit if escape was pressed
    if UserData.abort
       error('Operation terminated by user.'); 
    end
    
    % Return parameters
    params = struct();
    params.xc = UserData.xc;
    params.yc = UserData.yc;
    params.r1 = UserData.r1;
    params.r2 = UserData.r2;
end

