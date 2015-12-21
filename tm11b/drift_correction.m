function [data_rec, time, ...
          corr_cal, power_cal, pred_cal, time_cal,...
          data_rec_cal_mean, data_rec_cal_std ] ...
                   = drift_correction(data_rec, time, calibration_frames)
               
    % Correct a series of holographic reconstructions for phase drift,
    % using a set of interleaved calibration frames.
    %  - Damien Loterie (02/2014)
    %
    % Note: Also estimates power fluctuations (06/2014).
               
    % Separate calibration frames from TM frames
    data_rec_cal = data_rec(:,calibration_frames);
    time_cal     = time(calibration_frames);
    reference    = data_rec_cal(:,1);
    
    data_rec = data_rec(:,~calibration_frames);
    time     = time(~calibration_frames);
    
    % Estimation of drift and power fluctuations
    disp('Drift estimation...');
    [corr_cal, Rxy, ~, power_cal] = corr2c2(reference, data_rec_cal);
    pred_cal = Rxy./power_cal;
    
    % Phase interpolation
    sc = csapi(time_cal, corr_cal);
    
    comp = fnval(sc, time);
    comp_cal = fnval(sc, time_cal);
    
    comp     = comp     ./ abs(comp);
    comp_cal = comp_cal ./ abs(comp_cal);
    
    % Amplitude interpolation (only slow trends)
    pred_filt = imfilter(abs(pred_cal), fspecial('gaussian',[1 1000],100), 'symmetric');
    sp = csapi(time_cal, pred_filt);
    
    %warning('Amplitude correction is disabled.');
    comp     = comp     .* fnval(sp, time);
    comp_cal = comp_cal .* fnval(sp, time_cal);
    
    % Warning when some correlations are too low
    if any(abs(corr_cal)<0.80)
       warning('Some correlations are below threshold'); 
    end
    
    % Drift correction
    disp('Drift compensation...');
    for i=1:size(data_rec,2)
       %data_rec(:,i) = data_rec(:,i)*comp(i)/abs(comp(i));
       data_rec(:,i) = data_rec(:,i).*comp(i);
    end
    for i=1:size(data_rec_cal,2)
       %data_rec_cal(:,i) = data_rec_cal(:,i)*comp_cal(i)/abs(comp_cal(i));
       data_rec_cal(:,i) = data_rec_cal(:,i).*comp_cal(i);
    end
 
    % Get average data_rec_cal
    data_rec_cal_mean = mean(data_rec_cal,2);
    data_rec_cal_std = std(data_rec_cal,0,2);
    
    % Figures
    figure;
    phase_plot = unwrap(angle(corr_cal))/pi*180;
    plot(time_cal, phase_plot, 'r');
%     hold on;
%     plot(time_cal, unwrap(angle(corr_cal_old))/pi*180, 'rx');
%     hold off;
    ylabel('Phase drift [°]');
    xlabel('Time [s]');
    
    figure;
    plot(time_cal, 100*abs(corr_cal), 'b');
    ylabel('Correlation');
    xlabel('Time [s]');
    v = axis;
    v(3:4) = [0 100];
    axis(v);
    
    figure;
    amp_fluct_pct = 100*(abs(pred_cal)/median(abs(pred_cal(:)))-1);
    amp_corr_pct  = 100*(abs(comp_cal)/median(abs(comp_cal(:)))-1);
    plot(time_cal, amp_fluct_pct, 'k');
	hold on;
    plot(time_cal, amp_corr_pct, 'r');
	hold off;
    ylabel('Amplitude fluctuation [%]');
    xlabel('Time [s]');
    v = axis;
    v(3:4) = [floor(min(amp_fluct_pct)/5)*5 ceil(max(amp_fluct_pct)/5)*5];
    axis(v);
    
    pause(1);
end

