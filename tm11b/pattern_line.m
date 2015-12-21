function pattern = pattern_line(mask_output, dx, dy, l)
    % Function to generate a spot test pattern
    %  - Damien Loterie (02/2014)
    
    % Input processing
    if nargin<4
        l = 1;
    end
    if nargin<3
        dy = 0;
    end
    if nargin<2
        dx = 0;
    end
    
    % Calculate center coordinates
    x0 = round((find(max(mask_output,[],1),1,'first')+find(max(mask_output,[],1),1,'last'))/2);
    y0 = round((find(max(mask_output,[],2),1,'first')+find(max(mask_output,[],2),1,'last'))/2);
    
    xl = round(x0+dx);
    yl = round(y0+dy);
    
    if l>1
       yl = unique(round(yl + (0:(l-1)) - l/2));
    end
    
    
    % Put point
    pattern = zeros(size(mask_output));
    pattern(yl,xl) = 1;


end

