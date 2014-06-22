% Author:Johanna Kreither & Steve Luck
% Davis, CA, March 2011

function varargout = CFCDT_GUI3(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @CFCDT_GUI3_OpeningFcn, ...
      'gui_OutputFcn',  @CFCDT_GUI3_OutputFcn, ...
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

% -------------------------------------------------------------------------
function CFCDT_GUI3_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for CFCDT_GUI3
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

%
% Default buttons
%
set(handles.edit_nblock,'String', '1') % number of blocks
set(handles.edit_notpb,'String', '15') % number of trials
set(handles.edit_isi1,'String', '350') % number of blocks
set(handles.edit_isi2,'String', '550') % number of trials
set(handles.radiobutton_att_dis,'Value',1) % attend distractor
set(handles.radiobutton_att_BLUE,'Value', 1) % attend BLUE cue
set(handles.radiobutton_runpractice,'Value',1) % run practice
set(handles.figure1,'Name','CFCDT JK&SL');



% UIWAIT makes str2codeGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

% -------------------------------------------------------------------------
function varargout = CFCDT_GUI3_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);
pause(0.2)

% -------------------------------------------------------------------------
function radiobutton_att_BLUE_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_att_RED,'Value',0)
else
      set(hObject,'Value',1)
end
% -------------------------------------------------------------------------
function radiobutton_att_RED_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_att_BLUE,'Value',0)
else
      set(hObject,'Value',1)
end

% -------------------------------------------------------------------------
function edit1_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function radiobutton_att_dis_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      %set(handles.radiobutton_att_dis,'Value',1)
      set(handles.radiobutton_ignore_dis,'Value',0)
      set(handles.radiobutton_no_dis,'Value',0)
      set(handles.radiobutton_passive,'Value',0)
else
      set(hObject,'Value',1)
end

% -------------------------------------------------------------------------
function radiobutton_ignore_dis_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_att_dis,'Value',0)
      %set(handles.radiobutton_ignore_dis,'Value',1)
      set(handles.radiobutton_no_dis,'Value',0)
      set(handles.radiobutton_passive,'Value',0)
else
      set(hObject,'Value',1)
end

% -------------------------------------------------------------------------
function radiobutton_no_dis_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_att_dis,'Value',0)
      set(handles.radiobutton_ignore_dis,'Value',0)
      %set(handles.radiobutton_no_dis,'Value',1)
      set(handles.radiobutton_passive,'Value',0)
else
      set(hObject,'Value',1)
end

% -------------------------------------------------------------------------
function radiobutton_passive_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_att_dis,'Value',0)
      set(handles.radiobutton_ignore_dis,'Value',0)
      set(handles.radiobutton_no_dis,'Value',0)
      %set(handles.radiobutton_passive,'Value',1)
else
      set(hObject,'Value',1)
end

% -------------------------------------------------------------------------
function edit2_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function radiobutton_runtask_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      %set(handles.radiobutton_runtask,'Value',0)
      set(handles.radiobutton_runpractice,'Value',0)
      set(handles.radiobutton_runbehavior,'Value',0)
      set(handles.radiobutton_no_dis,'enable','on')
      set(handles.radiobutton_passive,'enable','on')
      set(handles.radiobutton_att_RED,'enable','on')
else
      set(hObject,'Value',1)
end
set(handles.edit_nblock,'String', '3')
set(handles.edit_notpb,'String', '60')
set(handles.edit_isi1,'String', '350') % number of blocks
set(handles.edit_isi2,'String', '550') % number of trials

% -------------------------------------------------------------------------
function radiobutton_runpractice_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_runtask,'Value',0)
      %set(handles.radiobutton_runpractice,'Value',0)
      set(handles.radiobutton_runbehavior,'Value',0)
      set(handles.radiobutton_no_dis,'enable','on')
      set(handles.radiobutton_passive,'enable','on')
      set(handles.radiobutton_att_RED,'enable','on')
else
      set(hObject,'Value',1)
end
set(handles.edit_nblock,'String', '1')
set(handles.edit_notpb,'String', '15')
set(handles.edit_isi1,'String', '350') % number of blocks
set(handles.edit_isi2,'String', '550') % number of trials

% -------------------------------------------------------------------------
function radiobutton_runbehavior_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_runtask,'Value',0)
      set(handles.radiobutton_runpractice,'Value',0)
      %set(handles.radiobutton_runbehavior,'Value',0)
      
      set(handles.radiobutton_no_dis,'enable','off')
      set(handles.radiobutton_passive,'enable','off')
      set(handles.radiobutton_att_RED,'enable','off')
else
      set(hObject,'Value',1)
end
set(handles.edit_nblock,'String', '3')
set(handles.edit_notpb,'String', '34')
set(handles.edit_isi1,'String', '1500') % number of blocks
set(handles.edit_isi2,'String', '1500') % number of trials

% -------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)
handles.output= '';
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function pushbutton_OK_Callback(hObject, eventdata, handles)

if get(handles.radiobutton_runtask, 'Value')
      taskmode = 1; % real task
else
      if get(handles.radiobutton_runpractice, 'Value')
            taskmode = 0; % practice
      else
            taskmode = 2; % behavior
      end
end
notpb = str2num(get(handles.edit_notpb, 'String'));
if isempty(notpb)
      return
end
nBlock = str2num(get(handles.edit_nblock, 'String'));
if isempty(nBlock)
      return
end
delay1 = str2num(get(handles.edit_isi1,'String'));
delay2 = str2num(get(handles.edit_isi2,'String'));
if isempty(delay1)
      return
end
if isempty(delay2)
      return
end
negval = find([notpb nBlock delay1 delay2]<0, 1);
if ~isempty(negval)
      warndlg('I found negative value(s) in your setting!','!! Warning !!')
      return
end
if get(handles.radiobutton_att_BLUE, 'Value')
      cuecolor = 'blue';
else
      cuecolor = 'red';
end
if get(handles.radiobutton_att_dis, 'Value')
      prefilename = '_att_dis';
      task = 1;
elseif get(handles.radiobutton_ignore_dis, 'Value')
      prefilename = '_ign_dis';
      task = 2;
elseif get(handles.radiobutton_no_dis, 'Value')
      prefilename = '_no_dis';
      task = 3;
else
      prefilename = '_passview';
      task = 4;
end
prefilename = [prefilename '_cue_' cuecolor];

disablegui(hObject, eventdata, handles);
%
% Call Task
%
CFCDT_AI_UI3(task, taskmode, notpb, nBlock, cuecolor, prefilename,delay1,delay2)

% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function edit_nblock_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_nblock_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit_notpb_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_notpb_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function disablegui(hObject, eventdata, handles)
set(handles.edit_nblock,'Enable', 'off') % number of blocks
set(handles.edit_notpb,'Enable', 'off') % number of trials

set(handles.radiobutton_att_BLUE,'Enable', 'off') % attend BLUE cue
set(handles.radiobutton_att_RED,'Enable', 'off') % attend RED cue

set(handles.radiobutton_runpractice,'Enable', 'off') % run practice
set(handles.radiobutton_runtask,'Enable', 'off') % run task
set(handles.radiobutton_runbehavior,'Enable', 'off') % run task

set(handles.radiobutton_att_dis,'Enable', 'off') %
set(handles.radiobutton_ignore_dis,'Enable', 'off') %
set(handles.radiobutton_no_dis,'Enable', 'off') %
set(handles.radiobutton_passive,'Enable', 'off') %

set(handles.pushbutton_cancel,'Enable', 'off') %
set(handles.pushbutton_OK,'Enable', 'off') %
return

%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
      % The GUI is still in UIWAIT, us UIRESUME
      uiresume(handles.figure1);
else
      % The GUI is no longer waiting, just close it
      delete(handles.figure1);
end

%--------------------------------------------------------------------------
function edit_isi1_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_isi1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_isi2_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_isi2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end
