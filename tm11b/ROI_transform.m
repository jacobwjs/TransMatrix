function [xb, yb] = ROI_transform(xa, ya, ROIa, ROIb, type)
    % [xb, yb] = ROI_transform(xa, ya, ROIa, ROIb, type)
    % Function to map coordinates from one ROI to another.
    %    - Damien Loterie (09/2014)

    % Defaults
    if nargin<5
       type = 'spatial'; 
    end

    % Convert positions
    switch type
        case 'spatial'
            xb = xa + ROIa(1) - ROIb(1);
            yb = ya + ROIa(2) - ROIb(2);
        case 'fftshift'
            pa = [xa,ya];
            p0a = center_of(ROIa(3:4));
            da = pa - p0a;
            
            p0b = center_of(ROIb(3:4));
            db = da./ROIa(3:4).*ROIb(3:4);
            pb = p0b + db;
            
            xb = pb(1);
            yb = pb(2);
        otherwise
            error('Unknown conversion type');
    end


end

