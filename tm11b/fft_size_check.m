function [res, N_new] = fft_size_check(N,message_type)
    % Quick function to check if the selected grid size will lead to an
    % optimal FFT speed
    %  - Damien Loterie (10/2015)

    % Check input
    if (N-round(abs(N)))>100*eps(N)
        error('Invalid argument.');
    else
        N = round(abs(N));
    end
    
    % Check grid size
    if max(factor(N))>7
        % Doesn't pass the factorization test
        res = false;
        
        % Find proposals for a better grid size
        if nargout>=2 || nargin<2 || ~strcmpi(message_type,'silent')
            % Look for grid sizes above
            N_above_odd  = [];
            N_above_even = [];
            N_test = N+1;
            while isempty(N_above_odd) || isempty(N_above_even)
                if max(factor(N_test))<=7
                    if mod(N_test,2)==0
                       if isempty(N_above_even)
                          N_above_even = N_test; 
                       end
                    else
                       if isempty(N_above_odd)
                          N_above_odd = N_test; 
                       end
                    end
                end
                N_test = N_test+1;
            end

            % Look for grid sizes below
            N_below_odd  = [];
            N_below_even = [];
            N_test = N-1;
            while (isempty(N_below_odd) || isempty(N_below_even)) && N_test>0
                if max(factor(N_test))<=7
                    if mod(N_test,2)==0
                       if isempty(N_below_even)
                          N_below_even = N_test; 
                       end
                    else
                       if isempty(N_below_odd)
                          N_below_odd = N_test; 
                       end
                    end
                end
                N_test = N_test-1;
            end
            
            % Collect new grid sizes
            N_new = [N_below_odd N_below_even N_above_even N_above_odd];
            [~,ind] = sort(abs(N_new-N),'ascend');
            N_new = N_new(ind);

            % Output error message
            msg = ['The current grid size (' int2str(N) ') will result in slow FFT speeds. ' ...
                   'Use a grid with one of the following sizes instead: ' int2str(N_new) '.'];
            if nargin>=2
                switch lower(message_type)
                    case 'error'
                        error(msg);
                    case 'warning'
                        warning(msg);
                    case 'display'
                        disp(msg);
                    case 'silent'
                    otherwise
                        warning(msg);
                        error('Invalid parameter.'); 
                end
            else
                warning(msg);
            end
        end
    else
       res = true; 
       N_new = N;
    end
end

