function  varargout = insertcodeonthefly2GUI(varargin)
%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright � 2007 The Regents of the University of California
% Created by Javier Lopez-Calderon and Steven Luck
% Center for Mind and Brain, University of California, Davis,
% javlopez@ucdavis.edu, sjluck@ucdavis.edu
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% Last Modified by GUIDE v2.5 23-Aug-2011 15:49:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @insertcodeonthefly2GUI_OpeningFcn, ...
      'gui_OutputFcn',  @insertcodeonthefly2GUI_OutputFcn, ...
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
function insertcodeonthefly2GUI_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = [];
% Update handles structure
guidata(hObject, handles);

try
      EEG = varargin{1};
      nchan  = EEG.nbchan; % Total number of channels
      
catch
      EEG = [];
      EEG.chanlocs = [];
      nchan  = 0;
end

%
% Prepare List of current Channels
%
listch = [];

if isempty(EEG.chanlocs)
      for e = 1:nchan
            EEG.chanlocs(e).labels = ['Ch' num2str(e)];
      end
end

for ch =1:nchan
      listch{ch} = [num2str(ch) ' = ' EEG.chanlocs(ch).labels ];
      set(handles.popupmenu_channel,'String', listch)
      set(handles.popupmenu_channel, 'Value', 1)
end

relalog = {'is equal to' 'is not equal to' 'is less than'...
      'is less than or equal to' 'is greater than or equal to' 'is greater than'};
set(handles.popupmenu_logical, 'String', relalog)
set(handles.popupmenu_logical, 'Value', 5) % default = 'is greater than or equal to'
set(handles.edit_threshold, 'String', '100')
set(handles.edit_newcode, 'String', '99')
set(handles.edit_refractory, 'String', '600')
set(handles.edit_latoffset, 'String', '0')

%
% Color GUI
%
handles = painterplab(handles);

% UIWAIT makes insertcodeonthefly2GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

% -------------------------------------------------------------------------
function varargout = insertcodeonthefly2GUI_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
% The figure can be deleted now
delete(handles.figure1);
pause(0.1)

% -------------------------------------------------------------------------
function edit_threshold_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_threshold_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit_newcode_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_newcode_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit_refractory_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_refractory_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)

handles.output = [];
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function pushbutton_RUN_Callback(hObject, eventdata, handles)

newcode = round(str2num(get(handles.edit_newcode,'String')));
channel = get(handles.popupmenu_channel,'Value');
relopv  = get(handles.popupmenu_logical,'Value');

switch relopv
      case 1
            relop = '==';
      case 2
            relop = '~=';
      case 3
            relop = '<';
      case 4
            relop = '<=';
      case 5
            relop = '>=';
      case 6
            relop = '>';
end

thresh     = str2num(get(handles.edit_threshold,'String'));
refract    = str2num(get(handles.edit_refractory,'String'));
absolud    = get(handles.checkbox_absolute,'Value');
windowms   = str2num(get(handles.edit_TWW,'String'));
durapercen = str2num(get(handles.edit_duration,'String'));
latoffset  = str2num(get(handles.edit_latoffset,'String'));

if isempty(newcode) || newcode==0
      msgboxText{1} =  'For this version, "new code" must be an integer number except zero (even if your working codes are strings).';
      title = 'ERPLAB: pop_insertcodeonthefly GUI';
      errorfound(msgboxText, title);
      return
end

if ~isempty(durapercen) && ~isempty(windowms)
      if durapercen<0 || durapercen>100
            msgboxText{1} =  'Duration parameter is in percentage of Test window width.';
            msgboxText{2} =  'It must be a number between (0 100)';
            title = 'ERPLAB: pop_insertcodeonthefly GUI';
            errorfound(msgboxText, title);
            return
      end
      if durapercen==0
            msgboxText{1} =  'Duration parameter is in percentage of Test window width.';
            msgboxText{2} =  'Using 0% is meaningless.';
            title = 'ERPLAB: pop_insertcodeonthefly GUI';
            errorfound(msgboxText, title);
            return
      end
elseif isempty(durapercen) && ~isempty(windowms)
      msgboxText{1} =  'You have to enter a duration parameter in a percentage of Test window width.';
      title = 'ERPLAB: pop_insertcodeonthefly GUI';
      errorfound(msgboxText, title);
      return
elseif ~isempty(durapercen) && isempty(windowms)
      msgboxText{1} =  'You have to enter a Test window width in ms.';
      title = 'ERPLAB: pop_insertcodeonthefly GUI';
      errorfound(msgboxText, title);
      return
end

outcell = {newcode channel relop thresh refract, absolud, windowms, durapercen, latoffset};
% Choose default command line output for insertcodeonthefly2GUI
handles.output = outcell;

% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function popupmenu_logical_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function popupmenu_logical_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function popupmenu_channel_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function popupmenu_channel_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
      %The GUI is still in UIWAIT, us UIRESUME
      handles.output = '';
      %Update handles structure
      guidata(hObject, handles);
      uiresume(handles.figure1);
else
      % The GUI is no longer waiting, just close it
      delete(handles.figure1);
end

% -------------------------------------------------------------------------
function checkbox_absolute_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_TWW_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_TWW_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit_duration_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_duration_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function checkbox_absolute_CreateFcn(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function pushbutton_RUN_CreateFcn(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function pushbutton_cancel_CreateFcn(hObject, eventdata, handles)


function edit_latoffset_Callback(hObject, eventdata, handles)


function edit_latoffset_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
