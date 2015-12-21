function patterns_plot_key(hfig, event)
	%  - Damien Loterie (07/2014)
	
    % Get data
    UserData = get(hfig,'UserData');

    % Actions
    switch (event.Key)
        % Change currently viewed experiment
        case 'rightarrow'
            UserData.i = min(size(UserData.experiments,2),UserData.i+1);
            % UserData.i = 1+mod(UserData.i,size(UserData.experiments,2));
        case 'leftarrow'
            UserData.i = max(1,UserData.i-1);
            % UserData.i = 1+mod(UserData.i-2,size(UserData.experiments,2));
        case 'downarrow'
            UserData.p = 1+mod(UserData.p,size(UserData.experiments,1));
        case 'uparrow'
            UserData.p = 1+mod(UserData.p-2,size(UserData.experiments,1));
        case 'escape'
            close(hfig);
        case 'return'
            close(hfig);
            
        case 'numpad1'
            UserData.m = 1;
        case 'numpad2'
            UserData.m = 2;
        case 'numpad3'
            UserData.m = 3;
        case 'numpad5'
            UserData.m = 5;
            
        case 'update'
        case 's'
            
        otherwise
            return;
    end
    
    % Abort if not a handle
    if ~ishandle(hfig)
        return;
    end
    
    % Update data
    set(hfig,'UserData',UserData);

    % Get parameters
    holo_params = UserData.holo_params;
    slm_params = UserData.slm_params;
    
    % Actual and desired images
    switch UserData.m
        case 1
            [~, region] = clip_mask(holo_params.freq.mask2c);

            label_a  = 'measurement';
            imga_fft = fftshift2(fft2(UserData.experiments(UserData.p, UserData.i).Hologram));
            imga_fft = unmask(mask(imga_fft,holo_params.freq.mask2), holo_params.freq.mask2c);
            %imga     = ifft2(ifftshift2(imga_fft));

            label_d  = 'pattern';
            imgd     = UserData.experiments(UserData.p, UserData.i).Pattern;
            imgd_fft = fftshift2(fft2(imgd));

            mask_comp = holo_params.freq.mask1c;
        case 2
            [~, region] = clip_mask(holo_params.freq.mask2c);

            label_a  = 'measurement';
            imga_fft = fftshift2(fft2(UserData.experiments(UserData.p, UserData.i).Hologram));
            imga_fft = unmask(mask(imga_fft,holo_params.freq.mask2),holo_params.freq.mask2c);
            %imga     = ifft2(ifftshift2(imga_fft));

            label_d  = 'model';
            imgd_fft = unmask(UserData.experiments(UserData.p, UserData.i).Y_sim_exp, holo_params.freq.mask1c);
            %imgd     = ifft2(ifftshift2(imgd_fft));

            mask_comp = holo_params.freq.mask1c;
        case 3
            [~, region] = clip_mask(holo_params.freq.mask2c);

            label_a  = 'model';
            imga_fft = unmask(UserData.experiments(UserData.p, UserData.i).Y_sim_exp, holo_params.freq.mask1c);
            %imga     = ifft2(ifftshift2(imga_fft));

            label_d  = 'pattern';
            imgd     = UserData.experiments(UserData.p, UserData.i).Pattern;
            imgd_fft = fftshift2(fft2(imgd));

            mask_comp = holo_params.freq.mask1c;

        case 5
            [~, region] = clip_mask(slm_params.freq.mask1);

            label_a  = 'slm';
            imga     = exp(2i*pi*double(UserData.experiments(UserData.p, UserData.i).SLM.')/256);
            imga_fft = fftshift2(fft2(imga));

            label_d  = 'input_inv';
            imgd_fft = unmask(UserData.experiments(UserData.p, UserData.i).X_inv, slm_params.freq.mask1);
            %imgd     = ifft2(ifftshift2(imgd_fft));

            mask_comp = slm_params.freq.mask1;

        otherwise
            error('Invalid number');
    end
    
    % Cut out desired regions
    imga_fft  = imga_fft(region(1):region(2), region(3):region(4)); 
    imgd_fft  = imgd_fft(region(1):region(2), region(3):region(4));
    mask_comp = mask_comp(region(1):region(2), region(3):region(4));

    % Normalize power
    imgd_fft = imgd_fft./sqrt(sum(abs(imgd_fft(mask_comp)).^2));

    % Scale to minimize error
    Rxy = sum(imgd_fft(mask_comp).*conj(imga_fft(mask_comp)));
    Ryy = sum(imga_fft(mask_comp).*conj(imga_fft(mask_comp)));
    imga_fft = (Rxy/Ryy)*imga_fft;
    
    % Define error
    imge_fft = imga_fft - imgd_fft;

    % Actual FFT plot
    subplot_tight(2,3,4);
    h_ffta = image(img_db_norm(imga_fft, false));
    axis image; axis off; box off;
    
    % Desired FFT plot
    subplot_tight(2,3,5);
    h_fftd = image(img_db_norm(imgd_fft, false));
    axis image; axis off; box off;

    % Error FFT plot
    subplot_tight(2,3,6);
    h_ffte = image(img_db_norm(imge_fft, false));
    axis image; axis off; box off;
    
    % Measured intensity plot
    I_meas = UserData.experiments(UserData.p, UserData.i).I_out - ...
             UserData.experiments(UserData.p, UserData.i).I_bg;
    I_meas = rescale(double(I_meas),[0.10,0.9999]);
    subplot_tight(2,3,1);
    h_int_meas = image(ind2rgb(round(1+255*I_meas),colormap(gray(256))));
    axis image; axis off; box off;
    
    % Desired intensity plot
    subplot_tight(2,3,2);
    I_pat = abs(UserData.experiments(UserData.p, UserData.i).Pattern).^2;
    I_pat = (I_pat-min(I_pat(:)))/(max(I_pat(:))-min(I_pat(:)));
    h_int_pat = image(ind2rgb(round(1+255*I_pat),colormap(gray(256))));
    axis image; axis off; box off;
    
    % Correlation information
    subplot_tight(2,3,3,[0.10 0.01]);
    corr_exp = abs(UserData.experiments(UserData.p, UserData.i).experimental_correlation);
    corr_pred = abs(UserData.experiments(UserData.p, UserData.i).predicted_correlation);
    corr_mod = abs(UserData.experiments(UserData.p, UserData.i).model_correlation);
    corr_in = abs(UserData.experiments(UserData.p, UserData.i).input_correlation);
    corr_int = UserData.experiments(UserData.p, UserData.i).intensity_correlation;
    
    bar_labels = {'XT', 'XM', 'MT', 'I', 'GS'};
    bar_labels{UserData.m} = ['\bf{' bar_labels{UserData.m} '}'];

    bar_pct([corr_exp, corr_mod, corr_pred, corr_int, corr_in],...
            bar_labels,...
            {['{\bfExperiment (' int2str(UserData.p) ', ' int2str(UserData.i) ')}'],' '});
    
    

    % Save images
    if strcmp(event.Key,'s')
        % Check directory
        if ~exist('./fig/','dir')
            mkdir('./fig/');
        end
        
        % Save
        save_str = ['./fig/' UserData.stamp_str ' exp(' num2str(UserData.p) ',' num2str(UserData.i) ') '];
        imwrite(get(h_ffta,'CData'), [save_str 'fft ' label_a '.png']);
        imwrite(get(h_fftd,'CData'), [save_str 'fft ' label_d '.png']);
        imwrite(get(h_ffte,'CData'), [save_str 'fft error' '(' label_a '-' label_d ').png']);
        imwrite(get(h_int_meas,'CData'), [save_str 'intensity measurement' '.png']);
        imwrite(get(h_int_pat,'CData'), [save_str 'intensity pattern' '.png']);

        % Display
        disp(['Images saved to ' save_str '*.*']);
    end

    

        
end

