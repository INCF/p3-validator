function varargout = deletechanGUI(varargin)


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @deletechanGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @deletechanGUI_OutputFcn, ...
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


% --- Executes just before deletechanGUI is made visible.
function deletechanGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to deletechanGUI (see VARARGIN)

% Choose default command line output for deletechanGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

typedata = varargin{1};

%
% Name & version
%
version = geterplabversion;
set(handles.figure1,'Name', ['ERPLAB ' version '   -   Remove Channel(s) GUI for ' typedata])

%
% Color GUI
%
handles = painterplab(handles);
drawnow
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = deletechanGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);
pause(0.1)

%--------------------------------------------------------------------------
function edit_chanindex_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_chanindex_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)

handles.output = [];
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

%--------------------------------------------------------------------------
function pushbutton_ok_Callback(hObject, eventdata, handles)

chanArray = str2num(get(handles.edit_chanindex,'String'));
handles.output = {chanArray}; % sent like a cell string (with formulas)


%formtype = handles.formtype;
%erpworkingmemory(formtype, formulalist);

%
% memory for Gui
%
%chanopGUI.emode = editormode;
%chanopGUI.hmode = get(handles.checkbox_sendfile2history,'Value');
%chanopGUI.listname  = listname;
%erpworkingmemory('chanopGUI', chanopGUI);

% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);
