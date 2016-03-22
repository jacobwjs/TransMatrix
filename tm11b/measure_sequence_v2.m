function [frames, metadata] = measure_sequence_v2(slm, ...
                                                    vid, ...
                                                    exposure, ...
                                                    sequence_function, ...
                                                    number_of_frames,...
                                                    freq_mask1)
    
    % Displays a sequence and measures the response on a camera.
    % Based on the work of Damien Loterie.
    %  - Jacob Staley (02/16)
    %
    % FIXME:
    %  - Needs to be updated to remove the explicit call to
    %    'trigger_camera'. A synchronization mechanism needs to be
    %    implemented.
    %  - Potentially can use 'trigger_camera' with synchronization enabled,
    %    and start the 'slm.Write_img()' in a thread using parpool.
    %  - Ideally a solution is found that bypasses the DAQ requirements.
    %    I'm still not convinced it's a necessary piece of hardware if we
    %    can use the SLM as a trigger source, and switch the camera
    %    exposure to be a value, rather than the triggerwidth.

    % Input check
    if ~isa(sequence_function, 'function_handle')
        error('Sequence function must be a function handle');
    end
    


    
    
    source = vid.source; % gigesource object.
    
    % Configure
    disp('Configuring...');
    set(source,'TriggerMode','On');
    set(source,'TriggerSource','Line1');
    set(source,'ExposureMode','TriggerWidth');
    
    % Configure
    disp('Starting...');
    start(vid);
    
%     % Prepare camera
%     for i=1:numel(fftp)
%         % Set counter
%         set(fftp{i}.source,'Counter_Image',0);
%         
%         % Used to be number_of_frames. It's actually (number_of_frames-1)
%         % if you don't count the test frame below.
%         set(fftp{i},'TriggerRepeat',Inf); 
%         
%         % Start camera
%         flushdata(fftp{i});
%         start(fftp{i});
%     end
    
%     % Test with one frame
%     % (this is needed to generate a first pulse, whereby the pulse
%     % configuration will be updated; if this is done during the measurement, it
%     % could take too much time and frames would be dropped)
%     d.show(sequence_function(1));
%     slm.Write_img(sequence_function(1));
%     for i=1:numel(fftp)
%         
%         % XXX: Replace me
%         trigger_camera(exposure, [], 1, false);
%         pause(0.25);
%         
%         getdata(fftp{i},1);
%     end
    
%     % Reset camera(s)
%     for i=1:numel(fftp)
%         set(fftp{i}.source,'Counter_Image',0);
%         flushdata(fftp{i});
%     end

%     % Start parallel display on a separate thread
%     if (nargin<6)
%         divider = 3;
%     end
%     p = parpool(1);
%     f = parfeval(p,@dx_fullscreen_parallel, 1, {sequence_function, number_of_frames, divider}, [], []);
% 
%     % Wait until display has actually started
%     disp('Waiting for the sequence to start...');
%     while d.getConfig('run')==false && isempty(f.Error)
%         pause(0.020);
%     end

    % Store various data about the execution.
    metadata = struct();
    metadata.Frame_acq_time = zeros(number_of_frames, 1);

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
    stall_threshold  = 10;
    %loop_counter     = 0;
    mem_counter      = 0;
    frames_grabbed = 0;
    
    
    % Holds all the images grabbed from the camera.
    frames = zeros(sum(sum(freq_mask1)), ... 
                   number_of_frames);
    
    % Start the progress meter.
    progress(0,number_of_frames);
    
     % Measure the sequence (non-parallel version).
    while frames_grabbed < number_of_frames;
        
        % A frame should only be available on the camera (i.e. video
        % source) after acquisition. 
        frames_grabbed = frames_grabbed + 1;
        
        % Write an entry in the sequence to the SLM.
        slm.Write_img(sequence_function(frames_grabbed));
        
        % XXX: Replace me with something synchronized
        [temp, metadata.Frame_acq_time(frames_grabbed)] = get_frame(vid, ...
                                                                    exposure, ...
                                                                    false);
                                                 
        frames(:, frames_grabbed) = mask(fftshift2(fft2(temp)), ...
                                         freq_mask1);
                                     
        
        
        % The 'fftp' object is basically a video source with the ability to
        % capture the images, crop, and take the FFT. We need to give time for the
        % exposure of the camera frame, calculation of FFT, and a little 
        % overhead for jitter (software timer) to keep everything properly
        % synchronized. The pause below should be roughly longer than
        % the 'exposure + FFT + software_timer_jitter'.
        %pause(exposure*1e-6 + 0.1e-3 + 100e-6);
        pause(30e-3);
        
      
        % % Progress meter
        if (mod(frames_grabbed, 200) == 0)
            progress(frames_grabbed, number_of_frames);
                    
            % Memory stats
            mem_counter = mem_counter + 1;
            [memu,mems] = memory;
            mem.Time(mem_counter) = toc(tic_acq);
            mem.MemUsedMATLAB(mem_counter) = memu.MemUsedMATLAB;
            mem.MemAvailableAllArrays(mem_counter) = memu.MemAvailableAllArrays;
            mem.PhysicalMemoryAvailable(mem_counter) = mems.PhysicalMemory.Available;
            mem.SystemMemoryTotal(mem_counter) = mems.SystemMemory.Available;          
        end
          
    end
    
%     % Measure the sequence (non-parallel version).
%     while frames_available < number_of_frames;
%         
%         % A frame should only be available on the camera (i.e. video
%         % source) after acquisition. It is only then that we want to
%         % display the next frame in the sequence on the SLM. Therefore we
%         % use the camera's 'FramesAvailable' counter to index into the
%         % sequence.
%         current_slm_img = frames_available + 1;
%         
%         % Write an entry in the sequence to the SLM.
%         slm.Write_img(sequence_function(current_slm_img));
%         
%         % XXX: Replace me
%         trigger_camera(exposure, [], 1, false);
%         
%         % The 'fftp' object is basically a video source with the ability to
%         % capture the images and take the FFT. We need to give time for the
%         % exposure of the camera frame, calculation of FFT, and a little 
%         % overhead for jitter (software timer) to keep everything properly
%         % synchronized. The pause below should be roughly longer than
%         % the 'exposure + FFT + software_timer_jitter'.
%         %pause(exposure*1e-6 + 0.1e-3 + 100e-6);
%         pause(4e-3);
%         
%         % Ensure everything is progressing (i.e. nothing has stalled in the
%         % SLM update and acquisition of images on the video source).
%         temp = get(fftp{i},'FramesAvailable');
%         if (frames_available == temp)
%             % If we make it here, nothing was updated on this pass, which
%             % means either the SLM didn't trigger the camera, or the camera
%             % failed to acquire the image. We give a small tolerance based
%             % on 'stall_counter'.
%             stall_counter = stall_counter + 1;
%         else
%             stall_counter = 0;
%         end
%         
%         % If we have missed multiple frames (SLM update and/or acquisition)
%         % we bail.
%         if (stall_counter == stall_threshold)
%             error('Acquisition stalled. Possible causes are SLM trigger out or camera trigger in');
%         end
%         
%         % Update how many frames the video source has captured.
%         % NOTE:
%         %  - This is also our index into 'sequence'.
%         frames_available = temp;
% 
%         % Progress meter
%         loop_counter = loop_counter+1;
%         if (frames_available > 0)
%             progress(frames_available, number_of_frames);
%         end
%         
%         % Memory stats
%         [memu,mems] = memory;
%         mem.Time(loop_counter) = toc(tic_acq);
%         mem.MemUsedMATLAB(loop_counter) = memu.MemUsedMATLAB;
%         mem.MemAvailableAllArrays(loop_counter) = memu.MemAvailableAllArrays;
%         mem.PhysicalMemoryAvailable(loop_counter) = mems.PhysicalMemory.Available;
%         mem.SystemMemoryTotal(loop_counter) = mems.SystemMemory.Available;
%         
%         % Wait
%         pause(2);
%     end
    
    % Keep information
    metadata.acquisition_time = toc(tic_acq); 
%     metadata.fdiary = f.Diary;
%     metadata.ferror = f.Error;
    
    % Trim memory array
    %mem.Time = mem.Time(1:loop_counter);
    mem.MemUsedMATLAB = mem.MemUsedMATLAB(1:mem_counter);
    mem.MemAvailableAllArrays = mem.MemAvailableAllArrays(1:mem_counter);
    mem.PhysicalMemoryAvailable = mem.PhysicalMemoryAvailable(1:mem_counter);
    mem.SystemMemoryTotal = mem.SystemMemoryTotal(1:mem_counter);
    metadata.memory = mem;

%     % Check for errors
%     if ~isempty(metadata.ferror)
%        disp(metadata.ferror);
%        error('Parallel job ended on an error'); 
%     end
% 
%     % Check for other messages
%     if ~isempty(metadata.fdiary)
%         warning('Parallel job diary non-empty');
%         disp(metadata.fdiary);
%     else
%         disp('No errors in the external thread.'); 
%     end
% 




%     % Clear pool
%     try
%         delete(p);
%     end
    
    

    % Message
    disp('Done acquiring.');
    disp(' ');
    toc(tic_acq);
    
%     % Images
%     disp('Getting image(s)');
%     data = getdata(fftp{1}, number_of_frames);
%     disp(['Frames gathered: ' int2str(size(data,2))]);
%     disp(['Frames left: ' int2str(get(fftp{1},'FramesAvailable'))]);
%     disp(['Frames left in source: ' int2str(get(fftp{1}.input_obj,'FramesAvailable'))]);

end

