function ROI = ROI_adapt(x0,y0, width, height)
    %ROI_ADAPT Function to create an ROI compatible with the 
    %          constraints of our Photonfocus cameras
    %          - Damien Loterie (03/2014)

    % Defaults
    xcam = 1312;
    ycam = 1082;
    ovl = 272;
    
    % Horizontal axis
    dx = width/2;
    xmin = min(xcam/2-ovl, floor(x0-dx)-1);
    xmax = max(xcam/2+ovl, ceil(x0+dx)-1);
    xmin = min(xcam-1,max(0,xmin));
    xmax = min(xcam-1,max(0,xmax));
    if mod(xmin,32)~=0
        xmin = xmin - mod(xmin,32);
    end
    if mod(xmax+1,32)~=0
        xmax = xmax - mod(xmax+1,32) + 32;
    end
    width = xmax-xmin+1;

    % Vertical axis
    if nargin<4 || isempty(height)
        height = width;
    else
        height = round(height);
    end
    ymin = round(y0-height/2)-1;
    ymax = ymin+height-1;
    ymin = min(ycam-1,max(0,ymin));
    ymax = min(ycam-1,max(0,ymax));
    height = ymax-ymin+1;

    % Final ROI
    ROI = [xmin ymin width height];
end

