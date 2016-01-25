function metadata = measure_sequence(d, ...
                                     vids, ...
                                     exposure, ...
                                     sequence_function, ...
                                     number_of_frames,...
                                     divider)
    % measure_sequence(d, vids, exposure, sequence_function, number_of_frames, divider)
    % Displays a sequence and measures the response on a camera.
    %
    % Note: We assume d and vid are properly configured beforehand.
	%  - Damien Loterie (07/2014)

    % Input check
    if ~isa(sequence_function, 'function_handle')
        error('Sequence function must be a function handle');
    end
    if ~iscell(vids)
       vids = num2cell(vids); 
    end

    % Configure dx_fullscreen
    if ~isempty(exposure)
        vsync_config(d, exposure);
    end
    
    % Prepare camera
    for i=1:numel(vids)
        % Set counter
        set(vids{i}.source,'Counter_Image',0);
        set(vids{i},'TriggerRepeat',Inf); % Used to be number_of_frames. It's actually (number_of_frames-1) if you don't count the test frame below.

        % Start camera
        flushdata(vids{i});
        start(vids{i});
    end
    
    % Test with one frame
    % (this is needed to generate a first pulse, whereby the pulse
    % configuration will be updated; if this is done during the measurement, it
    % could take too much time and frames would be dropped)
    d.show(sequence_function(1));
    
    for i=1:numel(vids)
        getdata(vids{i},1);
    end
    
    % Reset cameras
    for i=1:numel(vids)
        set(vids{i}.source,'Counter_Image',0);
        flushdata(vids{i});
    end

    % Start parallel display on a separate thread
    if (nargin<6)
        divider = 3;
    end
    p = parpool(1);
    f = parfeval(p,@dx_fullscreen_parallel, 1, {sequence_function, number_of_frames, divider}, [], []);

    % Wait until display has actually started
    disp('Waiting for the sequence to start...');
    while d.getConfig('run')==false && isempty(f.Error)
        pause(0.020);
    end

    % Memory tracking (pre-allocation)
    [~,mems] = memory;
    mem = struct();
    mem.Time = zeros(number_of_frames,1);
    mem.MemUsedMATLAB = zeros(number_of_frames,1);
    mem.MemAvailableAllArrays = zeros(number_of_frames,1);
    mem.PhysicalMemoryAvailable = zeros(number_of_frames,1);
    mem.PhysicalMemoryTotal = mems.PhysicalMemory.Total;
    mem.SystemMemoryTotal = zeros(number_of_frames,1);
    
    % Progress meter
    disp('Measuring...');
    tic_acq = tic;
    frames_available = 0;
    stall_counter    = 0;
    loop_counter     = 0;
    progress(0,number_of_frames);
    
    % Waiting loop
    while frames_available<number_of_frames && isempty(f.Error);
        if numel(vids)>0
            % Check how many frames have been acquired by each source
            frames_acquired_new = zeros(numel(vids),1);
            for i=1:numel(vids)
                frames_acquired_new(i) = get(vids{i},'FramesAvailable');
            end
            frames_acquired_new = min(frames_acquired_new);

            % Check if new frames are coming in or not (w.r.t. last iteration)
            if (frames_acquired_new==frames_available)
                stall_counter = stall_counter+1; 
            else
                stall_counter = 0;
            end
            if (stall_counter>10)
               try %#ok<TRYNC>
                   delete(p);
               end
               error('Acquisition stalled. Investigate causes using d.getConfig(''frameCounter''), get(vid.source,''Counter_Image''), get(vid.source,''Counter_MissedTrigger'') and get(vid).'); 
            end

            % Update frame count
            frames_available = frames_acquired_new;
        else
            frames_available = double(d.getConfig('frameCounter'));
        end

        % Progress meter
        loop_counter = loop_counter+1;
        if (frames_available>0)
            progress(frames_available,number_of_frames);
        end
        
        % Memory stats
        [memu,mems] = memory;
        mem.Time(loop_counter) = toc(tic_acq);
        mem.MemUsedMATLAB(loop_counter) = memu.MemUsedMATLAB;
        mem.MemAvailableAllArrays(loop_counter) = memu.MemAvailableAllArrays;
        mem.PhysicalMemoryAvailable(loop_counter) = mems.PhysicalMemory.Available;
        mem.SystemMemoryTotal(loop_counter) = mems.SystemMemory.Available;
        
        % Wait
        pause(1);
    end
    
    % Keep information
    metadata = struct();
    metadata.acquisition_time = toc(tic_acq); 
    metadata.fdiary = f.Diary;
    metadata.ferror = f.Error;
    
    % Trim memory array
    mem.Time = mem.Time(1:loop_counter);
    mem.MemUsedMATLAB = mem.MemUsedMATLAB(1:loop_counter);
    mem.MemAvailableAllArrays = mem.MemAvailableAllArrays(1:loop_counter);
    mem.PhysicalMemoryAvailable = mem.PhysicalMemoryAvailable(1:loop_counter);
    mem.SystemMemoryTotal = mem.SystemMemoryTotal(1:loop_counter);
    metadata.memory = mem;

    % Check for errors
    if ~isempty(metadata.ferror)
       disp(metadata.ferror);
       error('Parallel job ended on an error'); 
    end

    % Check for other messages
    if ~isempty(metadata.fdiary)
        warning('Parallel job diary non-empty');
        disp(metadata.fdiary);
    else
        disp('No errors in the external thread.'); 
    end

    % Get timing information from graphics process
    metadata.dx_time = fetchOutputs(f);

    % Stop camera after it is done recording
%     wait(vid,10,'Logging');
    for i=1:numel(vids)
        wait(vids{i},10,number_of_frames);
        stop(vids{i});
    end

    % Check that the time vectors match in size
    % (this is to verify that we captured the right number of frames)
    metadata.frames_available = zeros(numel(vids),1);
    disp(['Number of frames acquired: ' num2str(frames_available)]);
    for i=1:numel(vids)
        metadata.frames_available(i) = get(vids{i},'FramesAvailable');
        if numel(metadata.dx_time)~=metadata.frames_available(i)
           error(['The number of captured frames (' int2str(metadata.frames_available(i)) ') ' ....
                  'does not match the number of displayed frames (' int2str(numel(metadata.dx_time)) ') ' ...
                  'on camera ' int2str(i) '.']); 
        end
    end

    % Clear pool
    try
        delete(p);
    end
    
    % Message
    disp('Done acquiring.');
    disp(' ');
    toc(tic_acq);

end

