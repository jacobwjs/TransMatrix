function experiments = patterns_generate(patterns, ...
                                         inversions, ...
                                         T, ...
                                         input_to_slm,...
                                         slm_to_input,...
                                         field_to_output)
    % Generate input signals for the test patterns to validate the transmission matrix
    % - Damien Loterie (02/2014)

    % Create experiments
    experiments = struct();
	progress(0,numel(patterns)*numel(inversions));
    for i=1:numel(patterns)
        for j=1:numel(inversions)
            % Save desired pattern
            experiments(i,j).Pattern = patterns{i};
            
            % Save desired target vector
            experiments(i,j).Y_target = field_to_output(patterns{i});
            
            % Calculate corresponding input pattern
            experiments(i,j).X_inv = inversions(j).T_inv * experiments(i,j).Y_target;
            
            % Calculate the required SLM mask
            experiments(i,j).SLM = input_to_slm(experiments(i,j).X_inv);
            
            % From the SLM mask, get the experimental input that is actually sent to the fiber
            % (there may be distortions due to the use of a phase-only mask)
            experiments(i,j).X_inv_exp   = slm_to_input(experiments(i,j).SLM);

            % Simulate the output, both for the theoretical input and the
            % experimental input
            experiments(i,j).Y_sim       = T * experiments(i,j).X_inv;
            experiments(i,j).Y_sim_exp   = T * experiments(i,j).X_inv_exp;
            
            % Save inversion method
            experiments(i,j).InversionMethod = inversions(j).InversionMethod;
			
			% Progress meter
			progress((i-1)*numel(inversions) + j, numel(patterns)*numel(inversions));
        end
    end
    
end

