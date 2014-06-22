function varargout = importerpGUI(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @importerpGUI_OpeningFcn, ...
      'gui_OutputFcn',  @importerpGUI_OutputFcn, ...
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
function importerpGUI_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output   = [];
handles.fulltext = [];
handles.iniftype = [];

%{filename, pathname, ftype,includetime,timeunit,elabel,transpose,fs,xlim});
try
      def = varargin{1};
catch
      def = {'','','',0,1,0,0,1000,[-200 800]};
end

filename     = def{1};
pathname     = def{2};
ftype        = def{3};
includetime  = def{4};
timeunit     = def{5};
elabel       = def{6};
transpose    = def{7};
fs           = def{8};
xlim         = def{9};

%
% Set objects
%
nfile = length(filename);
fulltext = cell(1);

if nfile>0
      for i=1:nfile
            fulltext{i} = fullfile(pathname{i},filename{i});
      end
      fulltext  = cat(1, fulltext', {'new erpset'});
      set(handles.listbox_erpnames, 'String', fulltext');
else
      set(handles.listbox_erpnames, 'String', {'new erpset'});
end

set(handles.checkbox_time, 'Value', includetime) % time exists by default
% set(handles.edit_srate,'Enable','off')
% set(handles.edit_xlim,'Enable','off')
set(handles.edit_srate,'String', num2str(fs))
set(handles.edit_xlim,'String', num2str(xlim))
if timeunit==1
      set(handles.radiobutton_time_sec,'Value',1)
      set(handles.radiobutton_time_msec,'Value',0)
elseif timeunit==1E-3
      set(handles.radiobutton_time_sec,'Value',0)
      set(handles.radiobutton_time_msec,'Value',1)
else
      msgboxText =  ['No valid time unit.\n'...
            'Only 1 (sec) and 1E-3 (msec) are allowed.'];
      title = 'ERPLAB: importerpGUI() -> wrong input';
      errorfound(sprintf(msgboxText), title);
      return
end

set(handles.checkbox_elabels, 'Value', elabel) % time exists by default

if transpose==1
      set(handles.radiobutton_er_pc,'Value',1)
      set(handles.radiobutton_pr_ec,'Value',0)
else
      set(handles.radiobutton_er_pc,'Value',0)
      set(handles.radiobutton_pr_ec,'Value',1)
end

% Update handles structure
guidata(hObject, handles);

%
% Name & version
%
version = geterplabversion;
set(handles.figure1,'Name', ['ERPLAB ' version '   -   IMPORT AVERAGED ERP DATA GUI'])

%
% Color GUI
%
handles = painterplab(handles);

% UIWAIT makes grandaveragerGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);

% -------------------------------------------------------------------------
function varargout = importerpGUI_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);
pause(0.1)

% -------------------------------------------------------------------------
function listbox_erpnames_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function listbox_erpnames_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function pushbutton_adderpfile_Callback(hObject, eventdata, handles)

[erpfname, erppathname, findex] = uigetfile({'*.txt','Universal text format(*.txt)'; ...
      '*.avg','Neuroscan AVG format (*.avg)'; ...
      '*.txt','ERPSS text format (*.txt)'; ...
      '*.*',  'All Files (*.*)'}, ...
      'Select an edited file', ...
      'MultiSelect', 'on');


if isequal(erpfname,0)
      disp('User selected Cancel')
      return
else
      iniftype = handles.iniftype;
      if ~isempty(iniftype)
            if findex~= iniftype
                  %msgboxText =  'Different type of files cannot be put together within an ERPset.';
                  %title      = 'ERPLAB: permission denied';
                  %errorfound(msgboxText, title);
                  %return
                  fprintf('\nWARNING: You are putting together different formats of averaged files.\n\n')
            end
      else
            handles.iniftype = findex;
      end
      
      
      if ~iscell(erpfname)
            erpfname = {erpfname};
      end
      
      nerpn = length(erpfname);
      
      for i=1:nerpn
            
            newline  = fullfile(erppathname, erpfname{i});      % new member
            currline = get(handles.listbox_erpnames, 'Value');  % current position at the list
            fulltext = get(handles.listbox_erpnames, 'String'); % current list
            indxline = length(fulltext); % last line (virtual)
            
            if currline==indxline % is the current line the last line?
                  % extra line forward
                  fulltext  = cat(1, fulltext, {'new erpset'});
                  set(handles.listbox_erpnames, 'Value', currline+1)
            else
                  set(handles.listbox_erpnames, 'Value', currline)
                  resto = fulltext(currline:indxline);
                  fulltext  = cat(1, fulltext, {'new erpset'});
                  set(handles.listbox_erpnames, 'Value', currline+1)
                  [fulltext{currline+1:indxline+1}] = resto{:};
            end
            
            fulltext{currline} = sprintf('Bin %g\t@\t%s',currline, newline);
            set(handles.listbox_erpnames, 'String', fulltext)
      end
      
      indxline = length(fulltext);
      handles.indxline = indxline;
      handles.fulltext = fulltext;
      handles.listname = [];
      %set(handles.edit_filelist,'String','');
      % Update handles structure
      guidata(hObject, handles);      
end

% -------------------------------------------------------------------------
function pushbutton_delerpset_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
indxline = length(fulltext); % last line
fulltext = char(fulltext); % string matrix
currline = get(handles.listbox_erpnames, 'Value'); % current pos

if currline>=1 && currline<indxline
      
      fulltext(currline,:) = [];
      fulltext = cellstr(fulltext); % cell string
      nfile = length(fulltext);
      
      if nfile>1
            fulltext = regexprep(fulltext,'Bin.*?@','', 'ignorecase');
            fulltext = strtrim(fulltext);
            
            for i=1:nfile-1;
                  fulltext{i} = sprintf('Bin %g\t@\t%s',i, fulltext{i});
            end
      else
            handles.iniftype = [];
      end
      
      set(handles.listbox_erpnames, 'String', fulltext);
      listbox_erpnames_Callback(hObject, eventdata, handles)
      
      handles.fulltext = fulltext;
      %indxline = length(fulltext);
      %handles.listname = [];
      %set(handles.edit_filelist,'String','');
      
      % Update handles structure
      %guidata(hObject, handles);
end

% -------------------------------------------------------------------------
function pushbutton_up_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
indxline = length(fulltext); % last line
currline = get(handles.listbox_erpnames, 'Value'); % current pos

if currline>1 && currline<indxline
      
      auxft = fulltext{currline -1};
      fulltext{currline-1} = fulltext{currline};
      fulltext{currline}   = auxft;
      fulltext = regexprep(fulltext,'Bin.*?@','', 'ignorecase');% remove bin prefix
      fulltext = strtrim(fulltext);
      
      for i=1:length(fulltext)-1;
            fulltext{i} = sprintf('Bin %g\t@\t%s',i, fulltext{i}); % add bin prefix
      end
      
      set(handles.listbox_erpnames, 'String', fulltext);
      listbox_erpnames_Callback(hObject, eventdata, handles)
      set(handles.listbox_erpnames, 'Value', currline-1);
      handles.fulltext = fulltext;
      %indxline = length(fulltext);
      %handles.listname = [];
      %set(handles.edit_filelist,'String','');
      
      % Update handles structure
      %guidata(hObject, handles);
end

% -------------------------------------------------------------------------
function pushbutton_down_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
indxline = length(fulltext); % last line
currline = get(handles.listbox_erpnames, 'Value'); % current pos

if currline>=1 && currline<indxline-1
      
      auxft = fulltext{currline + 1};
      fulltext{currline+1} = fulltext{currline};
      fulltext{currline}   = auxft;
      fulltext = regexprep(fulltext,'Bin.*?@','', 'ignorecase');% remove bin prefix
      fulltext = strtrim(fulltext);
      
      for i=1:length(fulltext)-1;
            fulltext{i} = sprintf('Bin %g\t@\t%s',i, fulltext{i});% add bin prefix
      end
      
      set(handles.listbox_erpnames, 'String', fulltext);
      listbox_erpnames_Callback(hObject, eventdata, handles)
      set(handles.listbox_erpnames, 'Value', currline+1);
      handles.fulltext = fulltext;
      %indxline = length(fulltext);
      %handles.listname = [];
      %set(handles.edit_filelist,'String','');
      
      % Update handles structure
      %guidata(hObject, handles);
end

% -------------------------------------------------------------------------
function ok_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
fulltext = fulltext(1:end-1);
fulltext = regexprep(fulltext,'Bin.*?@','', 'ignorecase'); % remove bin prefix
fulltext = strtrim(fulltext);
filename = cell(1);
pathname = cell(1);
filetype = zeros(1, length(fulltext));

for i=1:length(fulltext)
      [pathstr, name, ext, versn] = fileparts(fulltext{i});
      pathname{i,1} = pathstr;
      filename{i,1} = [name ext];
      
      if strcmpi(ext,'.txt')
            filetype(i) = 1; % text 
      elseif strcmpi(ext,'.avg')
            filetype(i) = 2; % neuroscan
      else
            filetype(i) = 1; % text by default
      end
end

istime = get(handles.checkbox_time,'Value');

if get(handles.radiobutton_time_sec,'Value');
      tunit = 1;
end
if get(handles.radiobutton_time_msec,'Value');
      tunit = 1E-3;
end

iselabel = get(handles.checkbox_elabels,'Value');

if get(handles.radiobutton_er_pc,'Value');
      %nheaderlines = 0; % electrodes are rows, so there is not header.
      transpose = 1;
end
if get(handles.radiobutton_pr_ec,'Value');
      transpose = 0;
%       if iselabel==1
%             nheaderlines = 1; % electrodes are columns, so first row is electrode labels
%       else
%             nheaderlines = 0; 
%       end
end
srate = str2num(get(handles.edit_srate, 'String'));
xlim  = str2num(get(handles.edit_xlim, 'String'));

if (isempty(srate) || isempty(xlim)) && istime==0
      msgboxText =  ['Since there is not time info, you must specify\n'...
            'sampling rate in Hz, and time range (xmin xmax) in msec.'];
      title = 'ERPLAB: importerpGUI() -> missing input';
      errorfound(sprintf(msgboxText), title);
      return
end

if ~isempty(srate)
      if numel(srate)>1
            msgboxText =  'You must specify a unique value for sampling rate in Hz';
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
      if srate<=0
            msgboxText =  'You must specify a positive integer (no zero) value for sampling rate in Hz';
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
end
if ~isempty(xlim)
      if numel(xlim)~=2
            msgboxText =  'You must specify two values for time range [xmin xmax] in msec';
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
      if xlim(1)>=xlim(2)
            msgboxText =  ['Time range is incorrect.\n'...
                  'xmin must be lesser than xmax'];
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
      if xlim(1)>0 || xlim(2)<0
            msgboxText =  'time zero must be included within the time range.';
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
end


%
% filename = getlista{1};
% pathname = getlista{2};
% filetype = getlista{3};
% 
% istime   = getlista{4};
% tunit    = getlista{5};
% iselabel = getlista{6};
% nheaderlines  = getlista{7};


handles.output = {filename pathname filetype istime tunit iselabel transpose srate xlim};
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function cancel_Callback(hObject, eventdata, handles)
handles.output = [];
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);

% -------------------------------------------------------------------------
function edit1_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit2_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function pushbutton_CL_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
indxline = length(fulltext); % last line

if indxline>1      
      BackERPLABcolor = [1 0.9 0.3];    % yellow
      question{1} = 'Current list will be deleted.';
      question{2} = 'Are you sure?';
      title = 'List of averaged files for importing';
      oldcolor = get(0,'DefaultUicontrolBackgroundColor');
      set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
      button = questdlg(question, title,'Cancel','Yes', 'Cancel');
      set(0,'DefaultUicontrolBackgroundColor',oldcolor)
      
      if ~strcmpi(button,'Yes')
            return
      end
      
      set(handles.listbox_erpnames, 'Value', 1);
      set(handles.listbox_erpnames, 'String', {'new erpset'});
      handles.fulltext = [];
      handles.iniftype = [];
      % Update handles structure
      guidata(hObject, handles);
end

%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
      %The GUI is still in UIWAIT, us UIRESUME
      handles.output = [];
      %Update handles structure
      guidata(hObject, handles);
      uiresume(handles.figure1);
else
      % The GUI is no longer waiting, just close it
      delete(handles.figure1);
end

% -------------------------------------------------------------------------
function radiobutton_er_pc_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_pr_ec,'value', 0)
else
      set(handles.radiobutton_er_pc,'value', 1)
end

% -------------------------------------------------------------------------
function radiobutton_pr_ec_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_er_pc,'value', 0)
else
      set(handles.radiobutton_pr_ec,'value', 1)
end

% -------------------------------------------------------------------------
function checkbox_elabels_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function checkbox_time_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      %set(handles.edit_srate,'Enable','off')
      %set(handles.edit_xlim,'Enable','off')
      set(handles.radiobutton_time_sec,'Enable','on')
      set(handles.radiobutton_time_msec,'Enable','on') 
else
      %set(handles.edit_srate,'Enable','on')
      %set(handles.edit_xlim,'Enable','on')
      set(handles.radiobutton_time_sec,'Enable','off')
      set(handles.radiobutton_time_msec,'Enable','off')
end

% -------------------------------------------------------------------------
function edit_srate_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_srate_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function edit_xlim_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function edit_xlim_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
function radiobutton_time_sec_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_time_msec,'value',0)
else
      set(handles.radiobutton_time_sec,'value',1)
end

% -------------------------------------------------------------------------
function radiobutton_time_msec_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_time_sec,'value',0)
else
      set(handles.radiobutton_time_msec,'value',1)
end

% -------------------------------------------------------------------------
function pushbutton_take_a_look_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String'); % current list
indxline = length(fulltext); % last line
currline = get(handles.listbox_erpnames, 'Value'); % current pos

if currline>=1 && currline<indxline
      filename = fulltext{currline};
      filename = regexprep(filename,'Bin.*?@','', 'ignorecase');% remove bin prefix
      filename = strtrim(filename);
      
      [pathstr, name, ext, versn] = fileparts(filename) ;
      
      if ismember({ext},{'.txt' '.asc' '.ascii' '.csv' '.csa' '.dat' ''})
            uiopen(filename,1)
      else
            msgboxText =  'Current line does not refer a text file.';
            title = 'ERPLAB: importerpGUI() -> wrong input';
            errorfound(sprintf(msgboxText), title);
            return
      end
else
      msgboxText =  'Current line does not contain a valid filename.';
      title = 'ERPLAB: importerpGUI() -> wrong input';
      errorfound(sprintf(msgboxText), title);
      return
end
