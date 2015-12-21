function pattern = pattern_spot(mask_output, dx, dy)
    % Function to generate a spot test pattern
    %  - Damien Loterie (02/2014)
    
    % Input processing
    if nargin<3
        dy = 0;
    end
    if nargin<2
        dx = 0;
    end
    
    % Calculate center coordinates
    x0 = round((find(max(mask_output,[],1),1,'first')+find(max(mask_output,[],1),1,'last'))/2);
    y0 = round((find(max(mask_output,[],2),1,'first')+find(max(mask_output,[],2),1,'last'))/2);
    
    % Put point
    pattern = zeros(size(mask_output));
    pattern(round(y0+dy),round(x0+dx)) = 1;


end

