function frame = ROI_apply(frame, ROI)
    %ROI_APPLY Function to cut out an ROI from a frame
    %          - Damien Loterie (05/2014)

    % Defaults
    frame = frame((ROI(2)+1):(ROI(2)+ROI(4)), ...
                  (ROI(1)+1):(ROI(1)+ROI(3)));
end

