% This script iterates through a set of phase masks and records data from
% the detector attached to the NI-DAQ (PCIe-6321). 
% Jacob Staley, Nico Stasio (April, 2016)

%% 
% Compute the phase masks for the SLM to form spots at varous locations and
% depths based on the TM formed from the characterization of the fiber.

CREATE_SPOTS = false;
if (CREATE_SPOTS)
    
    % fiber_mask = holo_params.fiber.mask2;
    x_range = -30:10:30;
    y_range = -30:10:30;
    
    % Holds all of the SLM masks to form a range of spots. We want to pre-form
    % these to speed up the SLM update speed. Otherwise we are only able to
    % refresh the SLM as fast as we are able to calculate an FFT, reshape the
    % result, perform the matrix multiplication, and then form the iFFT and
    % reshape once again.
    spots = struct();
    spots.working_dist_100um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
    spots.working_dist_200um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
    spots.working_dist_300um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
    spots.working_dist_400um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
    spots.working_dist_500um = uint8(zeros(slm.x_pixels, slm.y_pixels, length(x_range)*length(y_range)));
    
    index = 0;
    
    % Boolean controlling how the scan is formed. Either line-by-line or raster
    % scanning.
    LINE_SCAN = false;
    RASTER_SCAN = ~LINE_SCAN; % We can only do one or the other type of scan.
    if (RASTER_SCAN)
        display('(Raster scan)');
    else
        display('(Line-by-line scan)');
    end
    
    % These values were found from a set of previous experiments and only make
    % sense to use with the imaging system in place to image the focus onto the
    % camera at different distances. If anything changes these values are
    % nonsensical.
    magnification_at_200um = 21.5;
    distance_200um = 4*25.4e-6;
    magnification_at_300um = 19.65;
    distance_300um = 8*25.4e-6;
    magnification_at_400um = 18.3;
    distance_400um = 12*25.4e-6;
    magnification_at_500um = 17.25;
    distance_500um = 16*25.4e-6;
    
    % Needed for propagation.
    camera_pixel_pitch = 8e-6;
    lambda = 785e-9;
    
    progress(0, length(x_range)*length(y_range));
    for i = x_range
        
        if (RASTER_SCAN)
            y_range = -1*y_range;
        end
        
        for j = y_range
            index = index + 1;
            
            % This must match the frame size used to form the transmission
            % matrix, otherwise the masking and indexing will fail below.
            output_to_propagate = zeros(camera_width_pixels, camera_height_pixels);
            % Form a 'focus spot' as an output.
            output_to_propagate(round(camera_width_pixels/2)+i,...
                round(camera_width_pixels/2)+j) = 1;
            
            % Initialize fields array.
            fields = [];
                        
            % If trained at a location (e.g. 100 um) then we don't need to
            % propagate.
            % FIXME:
            % - Why must 'i', and 'j' be swapped to match the indexing in
            % 'output_to_propagate'. Otherwise the spot is scanned differently.
            field_100um = pattern_spot(fiber_mask,j,i);
            
            % Otherwise we need to propagate for each distance.
            [field_200um] = propagate_v2(output_to_propagate, ...
                distance_200um, ...
                camera_pixel_pitch, ...
                lambda, ...
                magnification_at_200um);
            [field_300um] = propagate_v2(output_to_propagate, ...
                distance_300um, ...
                camera_pixel_pitch, ...
                lambda, ...
                magnification_at_300um);
            [field_400um] = propagate_v2(output_to_propagate, ...
                distance_400um, ...
                camera_pixel_pitch, ...
                lambda, ...
                magnification_at_400um);
            [field_500um] = propagate_v2(output_to_propagate, ...
                distance_500um, ...
                camera_pixel_pitch, ...
                lambda, ...
                magnification_at_500um);
            
            
            % Assign all the fields to be converted for each spot location and
            % depth.
            fields(:,:,1) = field_100um;
            fields(:,:,2) = field_200um;
            fields(:,:,3) = field_300um;
            fields(:,:,4) = field_400um;
            fields(:,:,5) = field_500um;
            
            
            % Walk through the transmission matrix backwards to get the mask
            % needed for the SLM to form the output we wanted.
            Y_targets = field_to_output(fields);
            X_invs = inversions.T_inv * Y_targets;
            SLM_propagated_masks = uint8(input_to_slm(X_invs));
            
            % Assign each mask for each spot to the given depth for later use.
            spots.working_dist_100um(:,:,index) = SLM_propagated_masks(:,:,1);
            spots.working_dist_200um(:,:,index) = SLM_propagated_masks(:,:,2);
            spots.working_dist_300um(:,:,index) = SLM_propagated_masks(:,:,3);
            spots.working_dist_400um(:,:,index) = SLM_propagated_masks(:,:,4);
            spots.working_dist_500um(:,:,index) = SLM_propagated_masks(:,:,5);
        end
        progress(index, length(x_range)*length(y_range));
    end
end % end (CREATE_SPOTS)



%% Scan spots and record data from attached detector.
%
% There are two types of detection due to the behavior of different detectors.
% 1) Analog signal
% 2) Edge counting
% To accomodate this, we set the DAQ (PCIe-6321) to record these two types
% of signals.


% % Use the data acquisition toolbox in Matlab to inialize a session.
% % XXX:
% % - Currently using Damien's front-end to the NI library. Maybe this option
% %   useful in the future.
% devs = daq.getDevices;
% s = daq.createSession('ni');
% s.DurationInSeconds = 0.10; % Set the acquisition duration.
% ch_ai0 = addAnalogInputChannel(s, 'Dev1', 'ai0', 'Voltage');
% tc = addTriggerConnection(s,'external','Dev1/PFI9','StartTrigger');
% tc.
% data = startForeground(s);
% figure, plot(data)


% %% Record analog signal (PMT or Thoralabs APD)
% % Damien's front end to the DLL's provided by NI.
% % Setup recording parameters
% samplesPerPulse = 256;
% pulsesPerFrame  = 3;
% samplesPerFrame = samplesPerPulse*pulsesPerFrame;
% 
% vsyncRate = 59.936540749;
% delayTime = 23917.92497267230e-6;
% vsyncTime = 1/vsyncRate;
% averagingTime = vsyncTime/16;
% repeatTime = vsyncTime/4;
% 
% N_spots = size(spots.working_dist_100um, 3);
% 
% clear chan;
% max_volt_range = 2;
% min_volt_range = 0;
% chan = DAQmxAnalogInput('Dev1/ai1','RSE', min_volt_range, max_volt_range);
% chan.CfgSampClkTiming('',samplesPerPulse/averagingTime,'rising','finite',samplesPerPulse);
% chan.CfgDigEdgeStartTrig('/Dev1/PFI9','falling');
% chan.StartTriggerRetriggerable = true;
% chan.InputBufferSize = samplesPerFrame*(N_spots+1);
% 
% 
% % Start the acquisition channel.
% start(chan);
% 
% % FIXME:
% % - Should spawn a thread to run this
% %  p = parpool(1);
% %    f = parfeval(p,@dx_fullscreen_parallel, 1, {sequence_function, number_of_frames, divider}, [], []);
% for i = 1:N_spots
%     slm_phase_mask = spots.working_dist_200um(:,:,i);
%     slm.Write_img(slm_phase_mask);
%     
%     % Pause for a short time with this phase map (i.e. spot) to collect
%     % flouresence.
%     pause(0.125);    
% end
% 
% % Read sensor
% %V_sensor = zeros(samplesPerFrame,numel(y_range),numel(x_range),N_spots/(numel(y_range)*numel(x_range)));
% % for i=1:N_spots
% %     V_sensor((1+(i-1)*samplesPerFrame):(i*samplesPerFrame)) = getdata(chan,samplesPerFrame);
% % end
% 
% DEBUG = true;
% 
% if (DEBUG) 
%     cmap = hsv(N_spots);  % Creates a N_spots-by-3 set of colors from the HSV colormap
%     figure, hold on;
% end
% 
% % Holds the resulting data from the detector.
% pmt_data = zeros(samplesPerPulse, N_spots);
% 
% for i=1:N_spots
%     pmt_data(:, i) = getdata(chan, samplesPerPulse);
%     if (DEBUG)
%         plot(pmt_data(:, 11), 'Color', cmap(i,:));  
%         drawnow;
%     end
%     %pause(0.025)
% end
% stop(chan);
% 
% % FIXME:
% % - verify sample count and implement averaging.
% %V_avg = shiftdim(mean(V_sensor,1),1);


%% Record using the photon counting APD.

vsyncRate = 59.936540749;
delayTime = 23917.92497267230e-6;
vsyncTime = 1/vsyncRate;
averagingTime = vsyncTime/16;
repeatTime = vsyncTime/4;

N_spots = size(spots.working_dist_100um, 3);

clear chan_digital_counter;
max_volt_range = 2;
min_volt_range = 0;
DAQ_counter_channel = 'Dev1/ctr1';
edge = 'rising'; % 'rising' or 'falling'
cnt_direction = 'up'; % 'up' or 'down'
initial_cnt = 0; 
chan_digital_counter = DAQmxCounterInputEdges(DAQ_counter_channel, ...
                                              edge, ...
                                              cnt_direction, ...
                                              initial_cnt);

                                          
chan.CfgSampClkTiming('',samplesPerPulse/averagingTime,'rising','finite',samplesPerPulse);
chan.CfgDigEdgeStartTrig('/Dev1/PFI9','falling');
chan.StartTriggerRetriggerable = true;
chan.InputBufferSize = samplesPerFrame*(N_spots+1);





