function varargout = EEG_IMAGE(varargin)
% EEG_IMAGE MATLAB code for EEG_IMAGE.fig
%      EEG_IMAGE, by itself, creates a new EEG_IMAGE or raises the existing
%      singleton*.
%
%      H = EEG_IMAGE returns the handle to a new EEG_IMAGE or the handle to
%      the existing singleton*.
%
%      EEG_IMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EEG_IMAGE.M with the given input arguments.
%
%      EEG_IMAGE('Property','Value',...) creates a new EEG_IMAGE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EEG_IMAGE_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EEG_IMAGE_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EEG_IMAGE

 
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EEG_IMAGE_OpeningFcn, ...
                   'gui_OutputFcn',  @EEG_IMAGE_OutputFcn, ...
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


% --- Executes just before EEG_IMAGE is made visible.
function EEG_IMAGE_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EEG_IMAGE (see VARARGIN)

% Choose default command line output for EEG_IMAGE
handles.output = hObject;
axes(handles.axes1);axis off
axes(handles.axes2); axis off
set(handles.edit2,'String','**');
set(handles.edit3,'String','**');
set(handles.edit1,'String','**');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EEG_IMAGE wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EEG_IMAGE_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global predicted_disease;
global file_name;

if ~exist('decision_tree_model.mat', 'file')
    features = [
        0.5, 0.2, 4.5; 
        0.6, 0.3, 5.0; 
        0.4, 0.1, 4.0;
        0.7, 0.4, 5.5; 
    ];
    labels = [1; 2; 1; 3]; 
    decision_tree_model = fitctree(features, labels);
    save('decision_tree_model.mat', 'decision_tree_model');
    disp('Decision Tree model created and saved as decision_tree_model.mat.');
else
    load('decision_tree_model.mat');
    disp('Decision Tree model loaded from decision_tree_model.mat.');
end

% Step 1: Select EEG Image
[file_name, file_path] = uigetfile({'*.png;*.jpg;*.tiff', 'Image Files (*.png, *.jpg, *.tiff)'}, 'Select an EEG Signal Image');
if isequal(file_name, 0)
    disp('No file selected. Exiting...');
    return;
end

% Load the selected input image
input_image_path = fullfile(file_path, file_name);
input_image = imread(input_image_path);
 axes(handles.axes1); 
imshow(input_image); title('Original Data');

% Convert to grayscale if necessary
if size(input_image, 3) == 3
    input_image = rgb2gray(input_image);
end
axes(handles.axes2); 
imshow(input_image); title('Grayscale Data');

% Step 3: Noise Removal   
denoised_image = medfilt2(input_image, [3 3]);  
 axes(handles.axes2); 
imshow(denoised_image); title('Denoised Data');

% Step 4: Image Enhancement using ESRGAN  
disp('Loading ESRGAN model...');
if ~exist('esrgan_model.mat', 'file')
    error('ESRGAN model file not found! Please ensure the ESRGAN model is trained and saved as esrgan_model.mat.');
end
load('esrgan_model.mat', 'esrgan_net');

disp('Enhancing image with ESRGAN...');
denoised_image_resized = imresize(denoised_image, [128, 128]); % Resize input for ESRGAN model
enhanced_image = predict(esrgan_net, denoised_image_resized); % Super-resolution enhancement

% Convert back to original size
enhanced_image_resized = imresize(enhanced_image, size(input_image));
%  axes(handles.axes2); 
% imshow(enhanced_image_resized); title('Enhanced Data');

% Save the enhanced image
output_dir = 'enhanced_eeg_plots';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
enhanced_image_path = fullfile(output_dir, ['enhanced_', file_name]);
imwrite(enhanced_image_resized, enhanced_image_path);

% Step 5: Feature Extraction & Classification
features = extract_features(enhanced_image_resized);
predicted_disease = predict(decision_tree_model, features);

% Display Results
run('Analysis.p');
fprintf('Predicted Disease: %d\n', predicted_disease);

if predicted_disease == 1
    set(handles.edit3, 'String', "Level 1");
 elseif predicted_disease == 2
    set(handles.edit3, 'String', "Level 2");
 elseif predicted_disease == 3
    set(handles.edit3, 'String', "level 3");
 else
    msgbox('Normal.');
end


% Step 6: Performance Comparison 
 input_image_double = im2double(input_image);
enhanced_image_double = im2double(enhanced_image_resized);
enhanced_image_double = max(0, min(enhanced_image_double, 1));
ssim_value = ssim(enhanced_image_double, input_image_double);
psnr_value = psnr(enhanced_image_double, input_image_double);
set(handles.edit1, 'String', num2str(ssim_value));
set(handles.edit2, 'String', num2str(psnr_value));

 

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
