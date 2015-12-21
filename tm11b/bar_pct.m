function h = bar_pct(percentages,labels,main_title)
    %BAR_PCT Custom bar plot for correlation percentages
	%   - Damien Loterie (05/2014)

    % Input check
    if any(percentages>1 | percentages<0)
       error('Invalid range'); 
    end
    
    % Defaults
    width = 0.8;
    x = (width/2)*[-1,-1,1,1];
    
    % Function for percentages
    function res = num2pct(n)
        if round(n*100)==100
            res = '100%';
        else
            res = [num2str(n*100,2) '%'];
        end
    end
    
    % Draw patches
    cla;
    for i=1:numel(percentages)
        % Patch positions
        p = percentages(i);
        y1 = p*[0,1,1,0];
        y2 = y1+[1,0,0,1];
        
        % Patches
        patch(i+x,y1,hsv2rgb([0.3 0.9 0.95]));
        patch(i+x,y2,hsv2rgb([0 0.8 0.95]));
        
        % Text
        text(i,p/2,num2pct(p),'VerticalAlignment','middle','HorizontalAlignment','center','FontSize',8);
        text(i,1-(1-p)/2,num2pct(1-p),'VerticalAlignment','middle','HorizontalAlignment','center','FontSize',8);
        
        % Labels
        if nargin>=2 && i<=numel(labels)
            text(i,0,labels{i},'VerticalAlignment','top','HorizontalAlignment','center');
        end
    end
    
    % Title
    if nargin>=3
        text((1+numel(percentages))/2,...
             1,...
             main_title,...
             'VerticalAlignment','bottom',...
             'HorizontalAlignment','center');
    end
    
    % Axes
    axis([0 numel(percentages)+1 0 1]);
    axis off;
end

