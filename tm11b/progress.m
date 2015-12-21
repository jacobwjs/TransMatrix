function progress(i, i_max)
	%  - Damien Loterie (03/2014)

    persistent ticID;
    persistent t_last;
    persistent characters_to_clear;

    % Regular call
    if i~=0
        % Display if at least 1 second has elapsed
        t = toc(ticID);
        if t>=(t_last+1) || (i>=i_max)
            % Record this time
            t_last = t;
            
            % Average iterations per second
            ips_avg = i/t;
            if ips_avg>0.1
                ips_avg_str = [num2str(round(ips_avg*10)/10) 'ips'];
            else
                ips_avg_str = [prettytime(1/ips_avg) ' per iteration'];
            end
            
            if (i>=i_max)
                % Make display string
                str = ['100%% (time elapsed: ' prettytime(t) '; average speed: ' ips_avg_str ')\n'];
                
                % Printout
                fprintf(1,[repmat('\b',[1 characters_to_clear]) str]);
                
                % Remember characters to clear
                characters_to_clear = numel(str)-2;
            else
                % Calculate progress percentage
                p = round(100*i/i_max);

                % Calculate time remaining
                t_rem = (i_max-i)*(t/i);
 
                % Make display string
                str = [num2str(p) '%% (time remaining: ' prettytime(t_rem) '; average speed: ' ips_avg_str ')\n'];
                
                % Printout
                fprintf(1,[repmat('\b',[1 characters_to_clear]) str]);
                
                % Remember characters to clear
                characters_to_clear = numel(str)-2;
            end
            
            
        end
        

    % First call
    else
        ticID = tic;
        t_last = 0;
        fprintf(1,'Progress: 0%%\n');
        characters_to_clear = 3;
    end
    
end

