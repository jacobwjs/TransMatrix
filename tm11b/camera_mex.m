function vid = camera_mex(name, trigger_type)
    % Returns a (preconfigured) camera object for measurements
    % This function uses a custom MEX interface based on the Pleora SDK
    % Usage:  vid = camera(name)
    %
    % - Damien Loterie (11/2014)

    % -------------------------------- JWJS ----------------
    addpath('../gige/gige_interface/gige_interface');
    % --------------------------------------
    
    % Check input
    narginchk(1,2);
    if nargin>=2
        if ~strcmpi(trigger_type,'ElectronicTrigger')
           error('Unsupported trigger type'); 
        end
    end

    % -------------------------------- JWJS ----------------
    % Initialize camera
    vid = gigeinput(name);
    % --------------------------------------
    source = vid.source;

    % Image parameters
	[xcam, ycam] = camera_size();
    set(vid,'ROIPosition',[0 0 xcam ycam]);
    set(source,'PixelFormat','Mono12');
    set(source,'DecimationVertical',1);
    set(source,'BlackLevel',100);
    
    % Videoinput trigger config
    triggerconfig(vid,'hardware');
    
    % Exposure mode
    set(source,'ExposureMode','TriggerWidth');

    % Trigger defaults
    set(source,'TriggerMode','On');
    set(source,'TriggerSource','Line1');
    set(source,'TriggerDelay',0);
    set(source,'TriggerDivider',1);
    set(source,'TriggerActivation','RisingEdge');
    set(source,'Trigger_EnBurstTrigger',false);
    
    % Other defaults
    set(source,'Counter_MissedBurstTrigger',0);
    set(source,'Counter_MissedTrigger',0);

    % Clear data
    flushdata(vid);

end

