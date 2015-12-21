function holography_cal_key(src, event)
	%   - Damien Loterie (07/2014)

    % Get data
    UserData = get(src,'UserData');

    % Actions
    switch (event.Key)
        case 'escape'
            UserData.done = true;
            UserData.abort = true;
        case 'return'
            UserData.done = true;
        case 'add'
            UserData.r1 = UserData.r1+1;
            UserData.r2 = UserData.r2+1;
        case 'subtract'
            UserData.r1 = max(1,UserData.r1-1);
            UserData.r2 = max(UserData.r1+1,UserData.r2-1); 
        case 'numpad9'
            UserData.r2 = UserData.r2+1;
        case 'numpad6'
            UserData.r2 = max(UserData.r1+1,UserData.r2-1);
        case 'r'
            [xp,yp] = ginput(1);
            dr = UserData.r2-UserData.r1;
            UserData.r1 = sqrt((UserData.xc-xp).^2 + (UserData.yc-yp).^2);
            UserData.r2 = UserData.r1 + dr;
        case 'm'
            [xp,yp] = ginput(1);
            UserData.r2 = max(UserData.r1+1, sqrt((UserData.xc-xp).^2 + (UserData.yc-yp).^2));
        case 'c'
            [UserData.xc,UserData.yc] = ginput(1);
        case 'leftarrow'
            UserData.xc = max(1,UserData.xc-1);
        case 'rightarrow'
            UserData.xc = min(size(UserData.img,2),UserData.xc+1);
        case 'uparrow'
            UserData.yc = max(1,UserData.yc-1);
        case 'downarrow'
            UserData.yc = min(size(UserData.img,1),UserData.yc+1);
        case 'update'
    end
    
    % Round coordinates
    UserData.xc = round(UserData.xc);
    UserData.yc = round(UserData.yc);
    UserData.r1 = round(UserData.r1);
    UserData.r2 = round(UserData.r2);
    
    % Clear
    if isfield(UserData,'h_r1') && ishandle(UserData.h_r1)
        delete(UserData.h_r1);
    end
    if isfield(UserData,'h_r2') && ishandle(UserData.h_r2)
        delete(UserData.h_r2);
    end
    
    % Redraw circles
    UserData.h_r1 = circle(UserData.xc,UserData.yc,UserData.r1,'r');
    UserData.h_r2 = circle(UserData.xc,UserData.yc,UserData.r2,'r');
    
    % Text box
    if ~isfield(UserData,'h_txt') || ~ishandle(UserData.h_txt)
        UserData.h_txt = text(1,1,'Initializing',...
                                  'HorizontalAlignment','Left',...
                                  'VerticalAlignment','Top',...
                                  'BackgroundColor',[0 0 0],...
                                  'EdgeColor',[1 1 1],...
                                  'Color',[1 1 1]);
    end
    set(UserData.h_txt,'String',...
                       {['Size: ' int2str(UserData.x) 'x' int2str(UserData.y)],...
                        ['M = (' int2str(UserData.xc) '; ' int2str(UserData.yc) ')'],...
                        ['r_1=' int2str(UserData.r1) ' / r_2=' int2str(UserData.r2)]});
    
    % Update data
    set(src,'UserData',UserData);
        
end

