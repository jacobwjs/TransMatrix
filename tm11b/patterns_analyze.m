function experiments = patterns_analyze(experiments, speckle_ref, fiber_mask)
    % Analyze the results of the validation experiments
    % - Damien Loterie (02/2014)

    % Enhancement, correlation, closeness to prediction
    
    % Correlation, prediction
    corr_exp = zeros(size(experiments));
    corr_pred = zeros(size(experiments));
    corr_mod = zeros(size(experiments));
    corr_input = zeros(size(experiments));
    for i=1:numel(experiments)
        corr_exp(i)   = corr2c(experiments(i).Y_target, ...
                               experiments(i).Y_meas, ...
                               'noshift');
                     
        corr_pred(i)  = corr2c(experiments(i).Y_target, ...
                               experiments(i).Y_sim_exp, ...
                               'noshift');             

        corr_mod(i)   = corr2c(experiments(i).Y_sim_exp, ...
                               experiments(i).Y_meas, ...
                               'noshift');

        corr_input(i) = corr2c(experiments(i).X_inv, ...
                               experiments(i).X_inv_exp, ...
                               'noshift');
                     
        experiments(i).experimental_correlation = corr_exp(i);
        experiments(i).predicted_correlation = corr_pred(i);
        experiments(i).model_correlation = corr_mod(i);
        experiments(i).input_correlation = corr_input(i);
    end
    
    % Enhancement, intensity correlation
    enh = zeros(size(experiments));
    corr_int       = zeros(size(experiments));
    corr_int_shift = zeros(size(experiments));
    for i=1:numel(experiments)
        % enh(i) = enhancement(experiments(i).I_out, experiments(i).I_bg, experiments(i).I_exposure, ...
                             % speckle_ref.I_out,    speckle_ref.I_bg,    speckle_ref.I_exposure, ...
                             % fiber_mask);

%         enh(i) = enhancement_alt(experiments(i).I_out, experiments(i).I_bg, fiber_mask);
                      
        I_meas_nobg = experiments(i).I_out-experiments(i).I_bg;
        I_pattern   = abs(experiments(i).Pattern).^2;
        I_meas_nobg = I_meas_nobg(fiber_mask);
        I_pattern   = I_pattern(fiber_mask);
        
        corr_int(i)       = corr2c(I_meas_nobg, I_pattern, 'noshift');
        corr_int_shift(i) = corr2c(I_meas_nobg, I_pattern);
                         
        % experiments(i).enhancement = enh(i);
        experiments(i).intensity_correlation         = corr_int(i);
        experiments(i).intensity_correlation_shifted = corr_int_shift(i);
    end
    
    % Display
    rows = cell(size(experiments,1),1);
    for i=1:numel(rows)
        rows{i} = ['P' num2str(i)];
    end
    cols = cell(1,size(experiments,2));
    for i=1:numel(cols)
        cols{i} = ['Inv' num2str(i)];
    end
    
    % Print out tables if possible
    if numel(size(experiments))==2
        disp('Experimental correlations (measured<->target):');
        disp_table(abs(corr_exp),@(n)num2str(round(n*100)/100),rows,cols);
        disp(' ');

        disp('Model correlation (measured<->model):');
        disp_table(abs(corr_mod),@(n)num2str(round(n*100)/100),rows,cols);
        disp(' ');

%         disp('Enhancement factor:');
%         disp_table(enh,@(n)num2str(round(n*100)/100),rows,cols);
%         disp(' ');
    end
    
    % Give warnings for overexposure
    for i=1:numel(experiments)
        % Check hologram
        if any(experiments(i).Hologram(:)>=saturation_level)
            warning(['Experiment (' num2str(i) '): hologram is overexposed.']);
        end

        % Check intensity image
        if any(experiments(i).I_out(:)>=saturation_level) 
            warning(['Experiment (' num2str(i) '): intensity image is overexposed.']);
        end
    end

end

