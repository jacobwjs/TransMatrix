function aim_close_callback(h_fig, ~)
	%   - Damien Loterie (06/2014)

    % Handles
     try 
        UserData_fig = get(h_fig, 'UserData');
        vid = UserData_fig.vid;
        ctr  = UserData_fig.ctr;
     catch
        warning('Unable to load the handles to the videoinput and counter objects.');
     end
    
    % Close counter
    try 
        if isvalid(ctr)
            ctr.stop();
            delete(ctr);
        end
    catch
        warning('Unable to delete the counter object.');
    end
    
    % Close video
    try
        if isvalid(vid)
            stop(vid);
            %delete(vid);
        end
    catch
        warning('Unable to delete the videoinput object.');
    end
    
    % Close figure
    delete(h_fig);

end

