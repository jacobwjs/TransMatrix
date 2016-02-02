


% Initialize the SLM.
run_test_patterns = true;
slm = Initialize_meadowlark_slm(run_test_patterns);

% Free the SLM.
Free_meadowlark_slm(slm);

clear slm;
clear run_test_patterns;