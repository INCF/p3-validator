=====

function varargout = utext2erpGUI(varargin)


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @utext2erpGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @utext2erpGUI_OutputFcn, ...
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

%--------------------------------------------------------------------------
function utext2erpGUI_OpeningFcn(hObject, eventdata, handles, varargin)


% Choose default command line output for utext2erpGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes utext2erpGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%--------------------------------------------------------------------------
function varargout = utext2erpGUI_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;
