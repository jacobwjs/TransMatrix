function aim_key_callback(h_fig, event)
	%   - Damien Loterie (06/2014)
   
    % Source and data
    UserData_fig = get(h_fig, 'UserData');
    vid = UserData_fig.vid;
    UserData_vid = get(vid,'UserData');
    source = getselectedsource(vid);
    
    % Handles
    ctr  = UserData_vid.Counter;
    
    % Useful data for saving snapshots
    stamp = clock;
    stamp_str = [num2str(stamp(1)) '-' num2str(stamp(2),'%02d') '-' num2str(stamp(3),'%02d') ' ' num2str(stamp(4),'%02d') '-' num2str(stamp(5),'%02d') '-' num2str(round(stamp(6)),'%02d')];
    ExposureTime = ctr.HighTime;
    DeviceID = get(source, 'DeviceID');
    
    % Actions
    switch (event.Key)
        case 'escape'
            UserData_fig.stop = 1;
            set(h_fig, 'UserData', UserData_fig);
        case 'q'
            UserData_fig.stop = 2;
            set(h_fig, 'UserData', UserData_fig);
        case 'subtract'
            ctr.stop();
            NewExposure = ExposureTime/2;
            ctr.HighTime     = NewExposure;
            ctr.InitialDelay = max(20e-9, UserData_vid.InitialDelayFunction(NewExposure));
            ctr.start();
        case 'add'
            ctr.stop();
            NewExposure = ExposureTime*2;
            ctr.HighTime     = NewExposure;
            ctr.InitialDelay = max(20e-9, UserData_vid.InitialDelayFunction(NewExposure));
            ctr.start();
        case 'f'
            UserData_vid.Fourier = ~UserData_vid.Fourier;
%             if (UserData_vid.Fourier)
%                 set(UserData_vid.h_r1,'Visible','on');
%                 set(UserData_vid.h_r2,'Visible','on');
%             else
%                 set(UserData_vid.h_r1,'Visible','off');
%                 set(UserData_vid.h_r2,'Visible','off');
%             end
            set(vid, 'UserData', UserData_vid);
        case 's'
            %frame = getsnapshot(vid); %#ok<NASGU>
            if isfield(UserData_fig,'frame') && ~isempty(UserData_fig.frame)
                frame = UserData_fig.frame; %#ok<NASGU>
            else
            	error('Frame not available'); 
            end
            
            
            if ~exist('./data/','dir')
                mkdir('./data/');
            end
            savepath = ['./data/' stamp_str ' snapshot.mat'];
            save(savepath, 'frame','stamp','ExposureTime','DeviceID');
            disp(['Snapshot saved to ' savepath]);
        case 'n'
            %frame = getsnapshot(vid); %#ok<NASGU>
            if isfield(UserData_fig,'frame') && ~isempty(UserData_fig.frame)
                frame = UserData_fig.frame; %#ok<NASGU>
            else
            	error('Frame not available'); 
            end
            
            name_str = input('Name for this snapshot: ','s');
            if ~exist('./data/','dir')
                mkdir('./data/');
            end
            savepath = ['./data/' stamp_str ' ' name_str '.mat'];
            save(savepath, 'frame','stamp','ExposureTime','DeviceID');
            disp(['Snapshot saved to ' savepath]);
            figure(h_fig);
        case 'i'
            %frame = getsnapshot(vid); %#ok<NASGU>
            if isfield(UserData_fig,'frame') && ~isempty(UserData_fig.frame)
                frame = UserData_fig.frame; %#ok<NASGU>
            else
            	error('Frame not available'); 
            end
            
            assignin('base', 'frame', frame);
            assignin('base', 'stamp', stamp);
            assignin('base', 'DeviceID', DeviceID);
            assignin('base', 'ExposureTime', ExposureTime);
            disp(['Snapshot ' stamp_str ' imported to the base workspace.']);
        case 'c'
            if (~UserData_vid.Fourier)
                UserData_vid.AutoContrast = ~UserData_vid.AutoContrast;
                set(vid,'UserData',UserData_vid);
            end
        case 't'
            UserData_vid.ShowCross = ~UserData_vid.ShowCross;
            set(vid,'UserData',UserData_vid);
        case 'g'
            UserData_vid.ShowGrid = ~UserData_vid.ShowGrid;
            set(vid,'UserData',UserData_vid);
        case 'r'
            UserData_vid.RangeMinMax = ~UserData_vid.RangeMinMax;
            set(vid,'UserData',UserData_vid);
%         otherwise
%             disp(event.Key);
    end

end

