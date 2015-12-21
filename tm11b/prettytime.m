function str = prettytime(t)
	%  - Damien Loterie (12/2013)
    if t<1
       str = '<1s'; 
    elseif t<(60-0.5)
       str = [num2str(round(t)) 's'];
    elseif t<(60*60-0.5)
       str = [num2str(round(t/60)) 'min.'];
    elseif t<(24*60*60-0.5)
       str = [num2str(round(t/(60*60))) 'h'];
    else
       str = [num2str(round(t/(24*60*60))) ' day(s)'];
    end

end

