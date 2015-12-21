function h = circle(x,y,r,color,varargin)
    % Function to plot a circle
    % - Damien Loterie (01/2014)
    
    h = rectangle('Position',[x-r,y-r,2*r,2*r],...
                  'Curvature',[1,1],...
                  varargin{:});
              
    if nargin>=4
       set(h,'EdgeColor',color); 
    else
       set(h,'EdgeColor','b'); 
    end
end

