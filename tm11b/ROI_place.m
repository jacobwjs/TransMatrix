function frame2 = ROI_place(frame1, frame2, ROI)
    % frame = ROI_place(frame1, frame2, ROI)
    % Place a frame1 into frame2 at a specified ROI
    %          - Damien Loterie (07/2014)

    % Select target range
    target_y = (ROI(2)+1):(ROI(2)+ROI(4));
    target_x = (ROI(1)+1):(ROI(1)+ROI(3));
    
    % Filter out of range values
    ind_y = (target_y>=1) & (target_y<=size(frame2,1));
    ind_x = (target_x>=1) & (target_x<=size(frame2,2));
    
    % Copy
    frame2(target_y(ind_y), target_x(ind_x)) = frame1(ind_y, ind_x);
end

