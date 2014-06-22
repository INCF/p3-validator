function varargout = epoch4avgGUI(varargin)
% EPOCH4AVGGUI M-file for epoch4avgGUI.fig
%      EPOCH4AVGGUI, by itself, creates a new EPOCH4AVGGUI or raises the existing
%      singleton*.
%
%      H = EPOCH4AVGGUI returns the handle to a new EPOCH4AVGGUI or the handle to
%      the existing singleton*.
%
%      EPOCH4AVGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EPOCH4AVGGUI.M with the given input arguments.
%
%      EPOCH4AVGGUI('Property','Value',...) creates a new EPOCH4AVGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before epoch4avgGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to epoch4avgGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help epoch4avgGUI

% Last Modified by GUIDE v2.5 28-Apr-2011 17:04:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @epoch4avgGUI_OpeningFcn, ...
      'gui_OutputFcn',  @epoch4avgGUI_OutputFcn, ...
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


% --- Executes just before epoch4avgGUI is made visible.
function epoch4avgGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for epoch4avgGUI
handles.output = hObject;
try
      nepochperdata  = varargin{1};
catch
      nepochperdata = 0;
end
handles.nepochperdata = nepochperdata;
% Update handles structure
guidata(hObject, handles);

ardetect_list = {'ignore artifact detection','exclude marked epochs (recommended)', 'include ONLY marked epochs (be cautios!)'};
catching_list = {'on the fly','at random', 'odd epochs', 'even epochs', 'prime epochs'};
instance_list = {'first','anywhere', 'last'};

set(handles.popupmenu_ardetection,'String', ardetect_list)
set(handles.popupmenu_catching,'String', catching_list)
set(handles.popupmenu_instance,'String', instance_list)

%
% Gui memory
%
epoch4avgGUI = erpworkingmemory('epoch4avgGUI');

if isempty(epoch4avgGUI)
      %Number of epochs per bin to average
      set(handles.radiobutton_asitis,'Value', 1)
      set(handles.radiobutton_asfollowed,'Value', 0)
      set(handles.edit_numberofepochsperbin,'Enable', 'off')
      
      %Artifact detection criterion
      set(handles.popupmenu_ardetection,'Value', 2)
      %set(handles.radiobutton_ignoreAD,'Value', 0)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 1)
      %set(handles.radiobutton_includeonlymarked,'Value', 0)
      
      % Epoch catching
      set(handles.popupmenu_catching,'Value', 1)
      %set(handles.radiobutton_onthefly,'Value', 1)
      %set(handles.radiobutton_atrandom,'Value', 0)
      %set(handles.radiobutton_oddepochs,'Value', 0)
      %set(handles.radiobutton_evenepochs,'Value', 0)
      
      % Epochs episode
      set(handles.radiobutton_fromanytime,'Value', 1)
      set(handles.radiobutton_frompart,'Value', 0)
      set(handles.edit_frompart,'Enable', 'off')
      %set(handles.edit_outof,'Enable', 'off')
      
      % Epoch instance
      set(handles.popupmenu_instance,'Value', 1)
      
      
      % Warn me
      set(handles.checkbox_warnme, 'Value', 1)
else
      nepochsperbin = epoch4avgGUI.nepochsperbin;
      ardetcriterio = epoch4avgGUI.ardetcriterio;
      epochcatching = epoch4avgGUI.epochcatching;
      epochsepisode = epoch4avgGUI.epochsepisode;
      warnme        = epoch4avgGUI.warnme;
      
      %Number of epochs per bin to average
      if ischar(nepochsperbin)
            set(handles.radiobutton_asitis,'Value', 1)
            set(handles.radiobutton_asfollowed,'Value', 0)
      else
            set(handles.radiobutton_asitis,'Value', 0)
            set(handles.radiobutton_asfollowed,'Value', 1)
            set(handles.edit_numberofepochsperbin,'Enable', 'on')
            set(handles.edit_numberofepochsperbin,'String', vect2colon(nepochsperbin,'Delimiter','off'))
      end
      
      %Artifact detection criterion
      set(handles.popupmenu_ardetection,'Value', ardetcriterio+1)
      
      %if ardetcriterio==0 % ignore
      %set(handles.radiobutton_ignoreAD,'Value', 1)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 0)
      %set(handles.radiobutton_includeonlymarked,'Value', 0)
      %elseif ardetcriterio==1 % only good trials (recommended)
      %set(handles.radiobutton_ignoreAD,'Value', 0)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 1)
      %set(handles.radiobutton_includeonlymarked,'Value', 0)
      %elseif ardetcriterio==2 % only bad trials (!)
      %set(handles.radiobutton_ignoreAD,'Value', 0)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 0)
      %set(handles.radiobutton_includeonlymarked,'Value', 1)
      %else % other (get default)
      %set(handles.radiobutton_ignoreAD,'Value', 0)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 1)
      %set(handles.radiobutton_includeonlymarked,'Value', 0)
      %end
      
      % Epoch catching
      
      set(handles.popupmenu_catching,'Value', epochcatching+1)
      %
      %       if epochcatching==0 % on the fly
      %             set(handles.radiobutton_onthefly,'Value', 1)
      %             set(handles.radiobutton_atrandom,'Value', 0)
      %             set(handles.radiobutton_oddepochs,'Value', 0)
      %             set(handles.radiobutton_evenepochs,'Value', 0)
      %       elseif epochcatching==1 % at random
      %             set(handles.radiobutton_onthefly,'Value', 0)
      %             set(handles.radiobutton_atrandom,'Value', 1)
      %             set(handles.radiobutton_oddepochs,'Value', 0)
      %             set(handles.radiobutton_evenepochs,'Value', 0)
      %       elseif epochcatching==2 % odd epochs
      %             set(handles.radiobutton_onthefly,'Value', 0)
      %             set(handles.radiobutton_atrandom,'Value', 0)
      %             set(handles.radiobutton_oddepochs,'Value', 1)
      %             set(handles.radiobutton_evenepochs,'Value', 0)
      %       elseif epochcatching==3 % even epochs
      %             set(handles.radiobutton_onthefly,'Value', 0)
      %             set(handles.radiobutton_atrandom,'Value', 0)
      %             set(handles.radiobutton_oddepochs,'Value', 0)
      %             set(handles.radiobutton_evenepochs,'Value', 1)
      %       else % default. On the fly
      %             set(handles.radiobutton_onthefly,'Value', 1)
      %             set(handles.radiobutton_atrandom,'Value', 0)
      %             set(handles.radiobutton_oddepochs,'Value', 0)
      %             set(handles.radiobutton_evenepochs,'Value', 0)
      %       end
      
      
      % Epochs episode
      part = epochsepisode{1}(1);
      total= epochsepisode{1}(2);
      
      if isempty(part) && isempty(total)
            set(handles.radiobutton_fromanytime,'Value', 1)
            set(handles.radiobutton_frompart,'Value', 0)
            set(handles.edit_frompart,'Enable', 'off')
            %set(handles.edit_outof,'Enable', 'off')
      else
            set(handles.radiobutton_fromanytime,'Value', 0)
            set(handles.radiobutton_frompart,'Value', 1)
            set(handles.edit_frompart,'Enable', 'on')
            %set(handles.edit_outof,'Enable', 'on')
            set(handles.edit_frompart,'String', vect2colon(part, 'Delimiter','off'))
            %set(handles.edit_outof,'String', num2str(total))
      end
      
      % Warn me
      if warnme
            set(handles.checkbox_warnme, 'Value', 1)
      else
            set(handles.checkbox_warnme, 'Value', 0)
      end
      
      
      
      
      
      
      
      
      %       asitis
      %       asfollowed
      %       numberofepochsperbin
      %
      %       ignoreAD
      %       excludemarkedepochs
      %       includeonlymarked
      %
      %       onthefly
      %       atrandom
      %       oddepochs
      %       evenepochs
      %
      %       fromanytime
      %       frompart
      %       warnme
      %
      
      
      
      
      
      
      incexc   = epoch4avgGUI.incexc ;
      chArray  = epoch4avgGUI.chArray;
      addref   = epoch4avgGUI.addref;
      equation = epoch4avgGUI.equation;
      
      if incexc
            set(handles.radiobutton_chan2inclu,'Value',1)
            set(handles.radiobutton_chan2exclu,'Value',0)
            set(handles.edit_includechan,'String',vect2colon(chArray,'Delimiter','off'));
            set(handles.edit_excludechan,'String','');
      else
            set(handles.radiobutton_chan2inclu,'Value',0)
            set(handles.radiobutton_chan2exclu,'Value',1)
            set(handles.edit_includechan,'String', '');
            set(handles.edit_excludechan,'String', vect2colon(chArray,'Delimiter','off'));
      end
      set(handles.checkbox_addrefchan2mydata,'Value', addref);  % 1 means yes
      set(handles.edit_equation,'String', equation);
end

%
% Color GUI
%
handles = painterplab(handles);
drawnow
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = epoch4avgGUI_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);
pause(0.1)
%-------------------------------------------------------------------------
function radiobutton_asitis_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_asfollowed,'Value', 0)
      set(handles.edit_numberofepochsperbin,'Enable', 'off')
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_asfollowed_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_asitis,'Value', 0)
      set(handles.edit_numberofepochsperbin,'Enable', 'on')
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function edit_numberofepochsperbin_Callback(hObject, eventdata, handles)

nepochperdata = handles.nepochperdata;
numperep      = str2num(get(hObject,'String'));

if ~isempty(numperep)
      if max(numperep)>max(nepochperdata)
            msgboxText =  ['Specified number of epochs does not seem realistic.\n'...
                  'The largest dataset for averaging only has &g epochs.'];
            title = 'ERPLAB: chanoperGUI few inputs';
            errorfound(sprintf(msgboxText, max(nepochperdata)), title);
            return
      end
end

%-------------------------------------------------------------------------
function edit_numberofepochsperbin_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------
function radiobutton_ignoreAD_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      %set(handles.radiobutton_ignoreAD,'Value', 0)
      set(handles.radiobutton_excludemarkedepochs,'Value', 0)
      set(handles.radiobutton_includeonlymarked,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_excludemarkedepochs_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_ignoreAD,'Value', 0)
      %set(handles.radiobutton_excludemarkedepochs,'Value', 0)
      set(handles.radiobutton_includeonlymarked,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_includeonlymarked_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_ignoreAD,'Value', 0)
      set(handles.radiobutton_excludemarkedepochs,'Value', 0)
      %set(handles.radiobutton_includeonlymarked,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_onthefly_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      %set(handles.radiobutton_onthefly,'Value', 0)
      set(handles.radiobutton_atrandom,'Value', 0)
      set(handles.radiobutton_oddepochs,'Value', 0)
      set(handles.radiobutton_evenepochs,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_atrandom_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_onthefly,'Value', 0)
      %set(handles.radiobutton_atrandom,'Value', 0)
      set(handles.radiobutton_oddepochs,'Value', 0)
      set(handles.radiobutton_evenepochs,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_oddepochs_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_onthefly,'Value', 0)
      set(handles.radiobutton_atrandom,'Value', 0)
      %set(handles.radiobutton_oddepochs,'Value', 0)
      set(handles.radiobutton_evenepochs,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_evenepochs_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_onthefly,'Value', 0)
      set(handles.radiobutton_atrandom,'Value', 0)
      set(handles.radiobutton_oddepochs,'Value', 0)
      %set(handles.radiobutton_evenepochs,'Value', 0)
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_fromanytime_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_frompart,'Value', 0)
      set(handles.edit_frompart,'Enable', 'off')
      %set(handles.edit_outof,'Enable', 'off')
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function radiobutton_frompart_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_fromanytime,'Value', 0)
      set(handles.edit_frompart,'Enable', 'on')
      %set(handles.edit_outof,'Enable', 'on')
else
      set(hObject,'Value', 1)
end

%-------------------------------------------------------------------------
function edit_frompart_Callback(hObject, eventdata, handles)

part  = str2num(get(hObject,'String'));
% total = str2num(get(handles.edit_outof,'String'));

if ~isempty(part) && ~isempty(total)
      
      part  = unique(part);
      total = unique(total);
      
      if length(total)>1
            msgboxText =  'Specified "out of" amount must be a single value.\n';
            title = 'ERPLAB: chanoperGUI few inputs';
            errorfound(msgboxText, title);
            return
      end
      if min(part)<1
            msgboxText =  'Specified "from part" value(s) cannot be lesser than 1 !.\n';
            title = 'ERPLAB: chanoperGUI few inputs';
            errorfound(msgboxText, title);
            return
      end
      if max(part)>total
            msgboxText =  ['Specified "from part" value =%g is larger than the specified total =%g value!.\n'];
            title = 'ERPLAB: chanoperGUI few inputs';
            errorfound(sprintf(msgboxText, max(part), total), title);
            return
      end
end

%-------------------------------------------------------------------------
function edit_frompart_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------
% function edit_outof_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------------
% function edit_outof_CreateFcn(hObject, eventdata, handles)
% 
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%       set(hObject,'BackgroundColor','white');
% end

%-------------------------------------------------------------------------
function checkbox_warnme_Callback(hObject, eventdata, handles)

%-------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)
handles.output = [];
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

%-------------------------------------------------------------------------
function pushbutton_OK_Callback(hObject, eventdata, handles)

%Number of epochs per bin to average
aival = get(handles.radiobutton_asitis,'Value'); % as it is
bival = get(handles.radiobutton_asfollowed,'Value'); % as followed

if aival && ~ bival
      nepochsperbin = 'all';
else
      nepochsperbin  = str2num(get(handles.edit_numberofepochsperbin,'String'));
end

% artifact detection criterion
cival = get(handles.radiobutton_ignoreAD,'Value'); % ignore AD
dival = get(handles.radiobutton_excludemarkedepochs,'Value'); % exclude marked epochs
eival = get(handles.radiobutton_includeonlymarked,'Value'); % include ONLY marked epochs

if cival && ~dival && ~eival
      ardetcriterio = 0;
elseif ~cival && dival && ~eival
      ardetcriterio = 1;
elseif ~cival && ~dival && eival
      ardetcriterio =2;
else
      ardetcriterio = 1;
end

% catching
fival = get(handles.radiobutton_onthefly,'Value'); % on the fly
gival = get(handles.radiobutton_atrandom,'Value'); % at random
hival = get(handles.radiobutton_oddepochs,'Value'); % odd epochs
iival = get(handles.radiobutton_evenepochs,'Value'); % even epochs

if fival && ~gival && ~hival && ~iival
      epochcatching = 0;
elseif ~fival && gival && ~hival && ~iival
      epochcatching = 1;
elseif ~fival && ~gival && hival && ~iival
      epochcatching =2;
elseif ~fival && ~gival && ~hival && iival
      epochcatching =3;
else
      epochcatching = 0;
end

% episode
jival = get(handles.radiobutton_fromanytime,'Value'); % from any time
kival = get(handles.radiobutton_frompart,'Value'); % from specific part of the recording

if jival && ~ kival
      epochsepisode{1}(1) = [];
      epochsepisode{1}(2) = [];
else
      part  = str2num(get(handles.edit_frompart,'String'));
%       total = str2num(get(handles.edit_outof,'String'));
      
      epochsepisode{1}(1) = part;
      epochsepisode{1}(2) = total;
end

warnme = get(handles.checkbox_warnme, 'Value');

handles.output = {nepochsperbin, ardetcriterio, epochcatching, epochsepisode, warnme};

%
% memory for Gui
%
epoch4avgGUI.nepochsperbin = nepochsperbin;
epoch4avgGUI.ardetcriterio = ardetcriterio;
epoch4avgGUI.epochcatching = epochcatching;
epoch4avgGUI.epochsepisode = epochsepisode;
epoch4avgGUI.warnme        = warnme;

erpworkingmemory('epoch4avgGUI', epoch4avgGUI);

% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

%--------------------------------------------------------------------------
function popupmenu_catching_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_catching_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_ardetection_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_ardetection_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
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

%--------------------------------------------------------------------------

function radiobutton12_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------

function radiobutton13_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------

function radiobutton14_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------

function radiobutton15_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------

function radiobutton16_Callback(hObject, eventdata, handles)


function popupmenu_instance_Callback(hObject, eventdata, handles)


function popupmenu_instance_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end
