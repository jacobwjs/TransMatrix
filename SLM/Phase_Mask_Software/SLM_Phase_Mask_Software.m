function varargout = SLM_Phase_Mask_Software(varargin)
% SLM_PHASE_MASK_SOFTWARE MATLAB code for SLM_Phase_Mask_Software.fig
%      SLM_PHASE_MASK_SOFTWARE, by itself, creates a new SLM_PHASE_MASK_SOFTWARE or raises the existing
%      singleton*.
%
%      H = SLM_PHASE_MASK_SOFTWARE returns the handle to a new SLM_PHASE_MASK_SOFTWARE or the handle to
%      the existing singleton*.
%
%      SLM_PHASE_MASK_SOFTWARE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLM_PHASE_MASK_SOFTWARE.M with the given input arguments.
%
%      SLM_PHASE_MASK_SOFTWARE('Property','Value',...) creates a new SLM_PHASE_MASK_SOFTWARE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SLM_Phase_Mask_Software_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SLM_Phase_Mask_Software_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SLM_Phase_Mask_Software

% Last Modified by GUIDE v2.5 04-Feb-2016 12:09:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SLM_Phase_Mask_Software_OpeningFcn, ...
    'gui_OutputFcn',  @SLM_Phase_Mask_Software_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SLM_Phase_Mask_Software is made visible.
function SLM_Phase_Mask_Software_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SLM_Phase_Mask_Software (see VARARGIN)

% Create an instance of the Meadowlark SDK.
run_tests = false;
handles.slm = slm_device('meadowlark', run_tests);


% Set a default constant grey level image.
handles.linear_tilt_enabled = get(handles.radiobutton_linear_tilt, 'Value');
handles.linear_tilt = uint8(zeros(handles.slm.x_pixels,...
                                  handles.slm.y_pixels));
handles.current_data = uint8(zeros(handles.slm.x_pixels,...
                                   handles.slm.y_pixels));
handles.phase_summation = [];
% Set default values for boolean flags used for toggling.
handles.colorbar_visible = false;
handles = update_image(handles);                      
% axes(handles.axes1);
% imagesc(handles.current_data);
% Update the image to the proper color scale for our 8-bit controller/SLM.
set_color_scale(handles);

% Choose default command line output for SLM_Phase_Mask_Software
handles.output = hObject;

% Setup the listeners for the sliders and default values.
handles = setup_sliders(hObject, handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SLM_Phase_Mask_Software wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SLM_Phase_Mask_Software_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu_phase_masks.
function popupmenu_phase_masks_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_phase_masks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_phase_masks contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_phase_masks

% Determin the selected data.
choice  = get(hObject, 'String');
val     = get(hObject, 'Value');

% Set the current data to the selected data set.
switch choice{val};
    case 'Blank Grey Level' % Constant phase of 0.
        handles.current_data = 255.*uint8(ones(handles.slm.x_pixels,...
            handles.slm.y_pixels));
        
        % Update the figure phase image.
        handles = update_image(handles);
        
        
    case 'Blazed Grating'
        % FIXME
        handles.current_data = uint8(zeros(handles.slm.x_pixels,...
            handles.slm.y_pixels));
        % Update the figure phase image.
        handles = update_image(handles);
        
    case 'Lens Phase'
        % FIXME
        handles.current_data = uint8(zeros(handles.slm.x_pixels,...
            handles.slm.y_pixels));
        % Update the figure phase image.
        handles = update_image(handles);
        
    case 'Random Bitmap'
        % Generate a 2D matrix of random integers between 0 and 255.
        handles.current_data = uint8(randi([0, 255],...
            handles.slm.x_pixels,...
            handles.slm.y_pixels));
        
        
        % Update the figure phase image.
        handles = update_image(handles);
        
    case 'Sinusoidal Grating'
        % FIXME
        handles.current_data = uint8(zeros(handles.slm.x_pixels,...
            handles.slm.y_pixels));
        % Update the figure.
        axes(handles.axes1);
        imagesc(handles.current_data);
        set_color_scale(handles);
        
    case 'Vortex Phase'
        % FIXME
        handles.current_data = uint8(zeros(handles.slm.x_pixels,...
            handles.slm.y_pixels));
        % Update the figure.
        axes(handles.axes1);
        imagesc(handles.current_data);
        set_color_scale(handles);
end

% Save handles structure.
guidata(hObject, handles)


% --- Executes on slider movement.
function slider_yaxis_Callback(hObject, eventdata, handles)
% hObject    handle to slider_yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Get the current value based on the position of the slider.
handles.slider_y_position = fix(get(hObject, 'Value'));

% Update the GUI.
%handles = updateGUI(handles);
set(handles.edit_slider_val_yaxis, 'String', handles.slider_y_position);

% Calculate the phase mask from the updated linear tilt for this axis.
handles = update_linear_tilt(hObject, handles);

% Update and display new linear tilt contribution.
handles = update_image(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider_yaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on slider movement.
function slider_xaxis_Callback(hObject, eventdata, handles)
% hObject    handle to slider_xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Get the current value based on the position of the slider.
handles.slider_x_position = fix(get(hObject, 'Value'));

% Update the GUI.
%handles = updateGUI(handles);
set(handles.edit_slider_val_xaxis, 'String', handles.slider_x_position);

% Calculate the phase mask from the updated linear tilt for this axis.
handles = update_linear_tilt(hObject, handles);

% Update and display new linear tilt contribution.
handles = update_image(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider_xaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes during object creation, after setting all properties.
function edit_slider_val_yaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_slider_val_yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uiputfile({'*.bmp'}, 'Save as');
if isequal(filename,0) || isequal(pathname,0)
    % User cancelled the save operation, just return.
    return
else
    imwrite(handles.phase_summation, [pathname, filename], 'bmp');
end



% --- Executes during object creation, after setting all properties.
function popupmenu_phase_masks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_phase_masks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uitoggletool_colorbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uitoggletool_colorbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Toggle between displayed states of the colorbar when the user clicks the
% toolbar.
if (handles.colorbar_visible)
    handles.colorbar_visible = false;
    colorbar('off');
else
    handles.colorbar_visible = true;
    set_color_scale(handles);
end


% Update handles structure
guidata(hObject, handles);



% -----------------------------------------------------------
function handles = set_color_scale(handles)
% We only have 8-bit PCIe interface, which limits us to 0 to 255 values for
% phase, so we set the image color scale accordingly.
caxis([0 255]);

% If we update to a new phase mask, and the colorbar was previously shown,
% keep it shown. If it wasn't then we need to do nothing.
if (handles.colorbar_visible)
    h = colorbar('northoutside');
    set(h, 'ytick', [0, 64, 128, 192, 255]);
end



% Sets the listeners so that as the sliders are changed we immediately have
% access to the values.
% -----------------------------------------------------------
function handles = setup_sliders(hObject, handles)
% Set the range and default values for the sliders.
set(handles.slider_xaxis, 'min', -256);
set(handles.slider_xaxis, 'max', 255);
set(handles.slider_xaxis, 'Value', 0);

set(handles.slider_yaxis, 'min', -256);
set(handles.slider_yaxis, 'max', 255);
set(handles.slider_yaxis, 'Value', 0);

set(handles.slider_xaxis, 'Sliderstep', [1/511 1/511]);
set(handles.slider_yaxis, 'Sliderstep', [1/511 1/511]);


handles.slider_x_position = 0;
handles.slider_y_position = 0;

% % Add listeners for slider_xaxis.
% if ~isfield(handles,'slider_xaxis_listener')
%     handles.slider_xaxis_listener = addlistener(handles.slider_xaxis,...
%                                                 'ContinuousValueChange',...
%                                                 @slider_xaxis_Callback);
% end

% % Add listeners for slider_yaxis.
% if ~isfield(handles,'slider_yaxis_listener')
%     handles.slider_yaxis_listener = addlistener(handles.slider_yaxis,...
%                                                 'ContinuousValueChange',...
%                                                 @slider_yaxis_Callback);
% end





% -----------------------------------------------------------
function handles = update_linear_tilt(hObject, handles)

x_pix = handles.slm.x_pixels;
y_pix = handles.slm.y_pixels;

% Preallocate
temp  = zeros(x_pix, y_pix);
phase = zeros(x_pix, y_pix);

% In k-space DC is centered in the middle of the image. We treat the
% sliders as if they are giving an offset from DC to produce the grating.
% Below we assign the value of the slider relative to the center of the
% image.
if ((handles.slider_x_position == 0) & ...
        (handles.slider_y_position == 0))
    % If the slider positions are in 0, they we leave a constant phase
    % mask of zero.
    phase = temp;
else
    temp(round(x_pix/2) - handles.slider_x_position,...
        round(y_pix/2) - handles.slider_y_position) = 1;
end
% Extract the phase from the field
phase = angle(fftshift(fft2(ifftshift(temp))));

% Scale the phase to appropriate values for the SLM.
handles.linear_tilt = uint8(mod(round(phase*256/(2*pi)), 256));



% -----------------------------------------------------------
function handles = update_image(handles)
% Calculate the current linear tilt contribution (if any) added to the
% current_data and display the resulting phase mask.
if (handles.linear_tilt_enabled)
    handles.phase_summation = mod(handles.current_data + handles.linear_tilt, 256);
else
    handles.phase_summation = handles.current_data;
end

% Update the SLM if the power is enabled.
if (handles.slm.slm_power_enabled)
    handles.slm_write_status = handles.slm.Write_img(handles.phase_summation);
end

% Update the GUI image.
axes(handles.axes1);
imagesc(handles.phase_summation);
set_color_scale(handles);



% --- Executes on button press in radiobutton_linear_tilt.
function radiobutton_linear_tilt_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_linear_tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_linear_tilt
handles.linear_tilt_enabled = get(hObject, 'Value');

handles = update_image(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in togglebutton1_SLM_power.
function togglebutton1_SLM_power_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton1_SLM_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton1_SLM_power
handles.slm_power = get(hObject, 'Value');

% Send the current state of the toggle button after it is clicked.
handles.slm.SLM_power(handles.slm_power);

% Update handles structure.
guidata(hObject, handles);


% --- Executes on button press in pushbutton_load_image.
function pushbutton_load_image_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_load_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


[filename, pathname] = uigetfile({'*.bmp';'*.jpg';'*.png';'*.*'});
if (isequal(filename, 0))
    disp('Load image cancelled');
    return;
else
    disp(['Loading image ', fullfile(pathname, filename), ' to the SLM']);
end
I = uint8(imread([pathname, filename]));

% FIXME
% - Need to put inside a while loop
% Check the pixel count to ensure the image fits on the device.
if ((size(I,1) > handles.slm.x_pixels) | ...
        (size(I,2) > handles.slm.y_pixels))
    fprintf('Error: Image size = %ix%i\n', size(I,1), size(I,2));
    fprintf('Image does not fit on the device (%ix%i)\n', handles.slm.x_pixels, handles.slm.y_pixels);
end

handles.current_data = I;

handles = update_image(handles);

% Update handles structure.
guidata(hObject, handles)



function handles = updateGUI(handles)
% set(handles.edit_slider_val_yaxis, 'String', handles.slider_y_position);
% set(handles.edit_slider_val_xaxis, 'String', handles.slider_x_position);


% -------------------------------------------------------------------------
function edit_slider_val_yaxis_Callback(hObject, eventdata, handles)
% hObject    handle to edit_slider_val_yaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_slider_val_yaxis as text
%        str2double(get(hObject,'String')) returns contents of edit_slider_val_yaxis as a double

% % Retrieve the new value from the edit box and assign it to the slider
% % position.
% new_val = fix(str2double(get(hObject, 'String')));
%
% % Set the slider to the new position, and call the 'callback' to update
% % everything else appropriately.
% set(handles.slider_yaxis, 'Value', new_val);
%
% % Update handles structure
% guidata(hObject, handles);
% slider_yaxis_Callback(handles.slider_yaxis, eventdata, handles);
%
% % Update handles structure
% guidata(hObject, handles);


% -------------------------------------------------------------------------
function edit_slider_val_xaxis_Callback(hObject, eventdata, handles)
% hObject    handle to edit_slider_val_xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_slider_val_xaxis as text
%        str2double(get(hObject,'String')) returns contents of edit_slider_val_xaxis as a double

% % Retrieve the new value from the edit box and assign it to the slider
% % position.
% new_val = fix(str2double(get(hObject, 'String')));
%
% % Set the slider to the new position, and call the 'callback' to update
% % everything else appropriately.
% set(handles.slider_xaxis, 'Value', new_val);
%
% % Update handles structure
% guidata(hObject, handles);
% slider_xaxis_Callback(handles.slider_xaxis, eventdata, handles);
%
% % Update handles structure
% guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit_slider_val_xaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_slider_val_xaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
