classdef slm_device < handle
    % A class that creates a middle layer between SLM and user to abstract
    % the details of each new SLM used.
    % - Jacob Staley (Feb. 2016)
    
    properties (GetAccess = public, SetAccess = private)
        % Struct that can be passed to functions giving information on the
        % SLM. 
        props = struct();
    end
    
    properties (SetAccess = public)
        % General properties.
        % -----------------------------------------------------------------
        
        
        
        
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
        
        % General properties of the device.
        % -----------------------------------------------------------------
        % Boolean showing whether or not the SLM is currently enabled.
        slm_power_enabled = false;
        
        % Dimensions of the SLM.
        x_pixels = 0;
        y_pixels = 0;
        pixel_size = 0;
        
        % Model of the SLM.
        model = [];
        
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
        function obj = slm_device(device_model, run_tests)
            % Figure out what kind of SLM we are working with.
            if strcmp(device_model, 'meadowlark')
                obj.sdk = Initialize_meadowlark_slm(run_tests);
                obj.slm_power_enabled   = true;
                obj.model               = device_model;
                obj.x_pixels            = 512;
                obj.y_pixels            = 512;
                obj.pixel_size          = 15e-6; %[meters]
                % Unsupported function call for the moment.
                %obj.overdrive       = calllib('Blink_SDK_C', 'Is_overdrive_available', obj.sdk);
            elseif strcmp(device_model, 'holoeye')
                display('Your SLM model is currently unsupported');
            else
                display('Error: the model of SLM chosen is invalid.');
            end
            
            % Assign the general properties of the SLM to the struct.
            obj.props.x_pixels      = obj.x_pixels;
            obj.props.y_pixels      = obj.y_pixels;
            obj.props.pixel_size    = obj.pixel_size;
            obj.props.model         = device_model;
            
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



