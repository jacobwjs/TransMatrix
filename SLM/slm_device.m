classdef slm_device < handle
    %SLM_DEVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public)
        % General properties.
        % -----------------------------------------------------------------
        % Boolean showing whether or not the SLM is currently enabled.
        slm_power_enabled = false;
        
        % Model of the SLM.
        model = [];
        
        % Dimensions of the SLM.
        x_pixels = 0;
        y_pixels = 0;
        
        % Meadowlark specific properties.
        % -----------------------------------------------------------------
        overdrive = true;
        
        % Board number.
        board_num = 1;
        
        
        % Holoeye specific properties.
        % -----------------------------------------------------------------
        % TODO
    end
    
    properties (SetAccess = private)
        % Meadowlark specific properties.
        % -----------------------------------------------------------------
        % Meadowlark Blink Overdrive SDK.
        sdk = [];
        
        % Define the triggering for the device. Default is SLM acts as
        % master, therefore we enable trigger out.
        wait_trig_in     = 0;
        pulse_trig_out    = 1;
        
        % Holoeye specific properties.
        % -----------------------------------------------------------------
        % TODO
    end
    
    methods
        % Constructor
        % -----------------------------------------------------------------
        function obj = slm_device(device_model)
            % Figure out what kind of SLM we are working with.
            if strcmp(device_model, 'meadowlark')
                obj.sdk = Initialize_meadowlark_slm(true);
                obj.slm_power_enabled   = true;
                obj.model               = device_model;
                obj.x_pixels            = 512;
                obj.y_pixels            = 512;
                % Unsupported function call for the moment.
                %obj.overdrive       = calllib('Blink_SDK_C', 'Is_overdrive_available', obj.sdk);
            elseif strcmp(device_model, 'holoeye')
                display('Your SLM model is currently unsupported');
            else
                display('Error: the model of SLM chosen is invalid.');
            end
            
        end
        
        % Destructor
        % -----------------------------------------------------------------
        function delete(obj)
            if (~isempty(obj.sdk))
                if (strcmp(obj.model, 'meadowlark'))
                    Free_meadowlark_slm(obj.sdk);
                end
            end
        end
        
        % Write image to the SLM.
        % -----------------------------------------------------------------
        function status = Write_img(obj, img)
            if (strcmp(obj.model, 'meadowlark'))
                % Write image to slm based on availability of overdrive.
                if (obj.overdrive)
                    status = calllib('Blink_SDK_C',...
                                    'Write_overdrive_image',...
                                    obj.sdk,...
                                    obj.board_num,...
                                    img,...
                                    obj.wait_trig_in,...
                                    obj.pulse_trig_out);
                else
                    % Assumes square image.
                    img_size = uint(size(img, 1));
                    status = calllib('Blink_SDK_C',...
                                    'Write_image',...
                                    obj.sdk,...
                                    obj.board_num,...
                                    img,...
                                    img_size,...
                                    obj.wait_trig_in,...
                                    obj.pulse_trig_out);
                end
            elseif (strcmp(obj.model, 'holoeye'))
                % TODO
            end
            
        end
        
        
        % Free the device (Meadowlark specific).
        % ----------------------------------------------------------
        function Release_meadowlark_SDK(obj)
            if (strcmp(obj.model, 'meadowlark'))
                Free_meadowlark_slm(obj.sdk);
                obj.sdk = [];
            end
        end
        
        % Toggles the power of the SLM based on the boolean value in
        % 'power_state'.
        % ------------------
        function status = SLM_power(obj, power_state)
            if (strcmp(obj.model, 'meadowlark'))
                status = calllib('Blink_SDK_C',...
                                 'SLM_power',...
                                 obj.sdk,...
                                 power_state);
                
                % Update the state of the SLM.
                obj.slm_power_enabled = power_state;
            end
        end
        
        
    end % end methods()
    
    
end



