function time = dx_fullscreen_parallel(sequence, config, startup)
    % This function allows to offload the sending of frames to the SLM on a
    % worker thread. Use as follows:
    %  p = parpool(1)
    %  f = parfeval(p, @dx_fullscreen_parallel, startup, config, sequence);
    %  time = fetchOutputs(f);
    %
    % Note that you will not get warnings about buffer underruns.
    % Check the time vector for this.
	% 
	%   - Damien Loterie (04/2014)

    % Arguments check
    narginchk(1,3);
    
    % Initialize
    if nargin>=3 && ~isempty(startup)
        dx_fullscreen.startup(startup{:});
    end
    d = dx_fullscreen;

    % Configure
    if nargin>=2 && ~isempty(config)
        fields = fieldnames(config);
        for i=1:numel(fields)
           d.setConfig(fields{i}, config(fields{i})); 
        end
    end
    pause(0.100);

    % Prepare frame stack
    d.loadSequence(sequence{:});

    % Play movie
    time = d.play;
    
    % Leave
    if nargin>=3 && ~isempty(startup)
        d.quit;
    end
    delete(d); clear d;
    
end