function f = fft_axis(N,fs)
    % f = fft_axis(N,fs)
    % Returns the frequency axis for an N-point FFT with sampling rate fs.
	%   - Damien Loterie (04/2014)

    f = [0:(N/2) (-(((N+mod(N,2))/2)-1):-1)];
%     f = [0:(N/2 + 1) (-(((N+mod(N,2))/2)-1):-1)];
    
    if nargin>=2
        Ts = 1/fs;
        Tp = N*Ts;
        df = 1/Tp;
        
        f = f*df;
    end
    
end

