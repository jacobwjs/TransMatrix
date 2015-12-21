function patterns_plot(experiments, ...
                       holo_params,...
                       slm_params,...
                       stamp_str)
                   
    %   Plotting function to explore the results of the validation
    %   experiments
    %   - Damien Loterie (05/2014)

    % Figure
    hfig = figure;

    % Pass data to figure
    UserData = struct();
    UserData.experiments = experiments;
    UserData.p = 1;
    UserData.i = 1;
    UserData.m = 1;
    UserData.holo_params = holo_params;
    UserData.slm_params = slm_params;
    UserData.stamp_str = stamp_str;
    set(hfig, 'UserData', UserData);
    
    % Maximize
    drawnow % Required to avoid Java errors
    jfig = get(handle(hfig), 'JavaFrame'); 
    jfig.setMaximized(true);

    % Key handler
    set(hfig, 'KeyPressFcn', @patterns_plot_key)

    % Initialize
    patterns_plot_key(hfig, struct('Key','update'));
end

