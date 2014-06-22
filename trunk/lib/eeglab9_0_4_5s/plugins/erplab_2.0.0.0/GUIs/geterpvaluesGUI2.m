%
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

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

function varargout = geterpvaluesGUI2(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
      'gui_Singleton',  gui_Singleton, ...
      'gui_OpeningFcn', @geterpvaluesGUI2_OpeningFcn, ...
      'gui_OutputFcn',  @geterpvaluesGUI2_OutputFcn, ...
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

%--------------------------------------------------------------------------
function geterpvaluesGUI2_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for geterpvaluesGUI2
handles.output   = [];
handles.indxline = 1;
handles.listname = [];
handles.owfp = 0;  % over write file permission

try
      ALLERP = varargin{1}; %evalin('base', 'ALLERP');
      
      if isstruct(ALLERP)
            handles.xmin  = ALLERP(1).xmin;
            handles.xmax  = ALLERP(1).xmax;
            handles.srate = ALLERP(1).srate;
            handles.nsets = length(ALLERP);
      else
            handles.xmin  = [];
            handles.xmax  = [];
            handles.srate = [];
            handles.nsets = [];
      end
catch
      ALLERP = [];
      handles.xmin  = [];
      handles.xmax  = [];
      handles.srate = [];
      handles.nsets = [];
end

try
      memoryinput = varargin{2};
      handles.memoryinput = memoryinput;
catch
      memoryinput = [];
      handles.memoryinput = memoryinput;
end

handles.ALLERP = ALLERP;
handles.b2filter = 0;

% Update handles structure
guidata(hObject, handles);

setall(hObject, eventdata, handles)

%
% Color GUI
%
handles = painterplab(handles);

%
% Set Measurement menu
%
set(handles.popupmenu_measurement, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_pol_amp, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_samp_amp, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_locpeakreplacement, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_fracreplacement, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_bins, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_precision, 'Backgroundcolor',[1 1 0.8])
set(handles.popupmenu_channels, 'Backgroundcolor',[1 1 0.8])
drawnow

% UIWAIT makes geterpvaluesGUI2 wait for user response (see UIRESUME)
uiwait(handles.figure1);

%--------------------------------------------------------------------------
function varargout = geterpvaluesGUI2_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
% The figure can be deleted now
delete(handles.figure1);
pause(0.1)

%--------------------------------------------------------------------------
function menupeakoff(hObject, eventdata, handles)
set(handles.popupmenu_pol_amp, 'Enable', 'off')
set(handles.text_pre, 'Enable', 'off')
set(handles.popupmenu_samp_amp, 'Enable', 'off')
set(handles.text_samp, 'Enable', 'off')
set(handles.text12, 'Enable', 'off')
set(handles.popupmenu_locpeakreplacement, 'Enable', 'off')

%--------------------------------------------------------------------------
function menupeakon(hObject, eventdata, handles)
set(handles.popupmenu_pol_amp, 'Enable', 'on')
set(handles.text_pre, 'Enable', 'on')
set(handles.popupmenu_samp_amp, 'Enable', 'on')
set(handles.text_samp, 'Enable', 'on')
set(handles.text12, 'Enable', 'on')
set(handles.popupmenu_locpeakreplacement, 'Enable', 'on')

%--------------------------------------------------------------------------
function menufareaoff(hObject, eventdata, handles)
set(handles.text_fraca,'Enable','off')
set(handles.popupmenu_fraca,'String', {''})
set(handles.popupmenu_fraca,'Enable','off')
set(handles.text_punit,'Enable','off')
set(handles.popupmenu_fracreplacement,'Enable','off')
set(handles.text19, 'Enable', 'off')

%--------------------------------------------------------------------------
function menufareaon(hObject, eventdata, handles)
set(handles.text_fraca,'Enable','on')
set(handles.text_punit,'Enable','on')
set(handles.popupmenu_fraca,'Enable','on')
%if get(handles.popupmenu_measurement, 'Value')~=8
set(handles.popupmenu_fracreplacement,'Enable','on')
set(handles.text19, 'Enable', 'on')
%else
%      set(handles.popupmenu_fracreplacement,'Enable','off')
%      set(handles.text19, 'Enable', 'off')
%end
fracarray = 0:100;
set(handles.popupmenu_fraca,'String', cellstr(num2str(fracarray')))
set(handles.text19, 'Enable', 'on')

%--------------------------------------------------------------------------
function edit_fname_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_fname_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function button_browse_Callback(hObject, eventdata, handles)

%
% Save OUTPUT file
%
prename = get(handles.edit_fname,'String');

if ispc
      [filename, filepath, filterindex] = uiputfile({'*.xls';'*.txt';'*.dat';'*.*'}, 'Save Output file as', prename);
else
      [filename, filepath, filterindex] = uiputfile({'*.txt';'*.dat';'*.*'}, 'Save Output file as', prename);
end

if isequal(filename,0)
      disp('User selected Cancel')
      handles.owfp = 0;  % over write file permission
      guidata(hObject, handles);
      return
else
      
      [px, fname, ext, versn] = fileparts(filename);
      
      if ispc
            if filterindex==2 || filterindex==4
                  ext2   = '.txt';
            elseif filterindex==3
                  ext2   = '.dat';
            else
                  ext2   = '.xls';
            end
      else
            if filterindex==1 || filterindex==3
                  ext2   = '.txt';
            else
                  ext2   = '.dat';
            end
      end
      
      fname = [ fname ext2];
      fullname = fullfile(filepath, fname);
      set(handles.edit_fname,'String', fullname);
      disp(['To Save Output file, user selected ', fullname])
      handle.fname     = fname;
      handle.pathname  = filepath;
      handles.owfp     = 1;  % over write file permission
      set(handles.edit_fname,'String', fullfile(filepath, fname));
      
      % Update handles structure
      guidata(hObject, handles);
end

%--------------------------------------------------------------------------
function edit_latency_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_latency_CreateFcn(hObject, eventdata, handles)

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
function pushbutton_run_Callback(hObject, eventdata, handles)

if get(handles.radiobutton_erpset, 'Value')
      
      erpset = str2num(char(get(handles.edit_erpset, 'String')));
      
      %       if isempty(erpset)
      %             msgboxText =  ['No ERPset indices were specified!\n\n'...
      %                   'You must use any integer value(s) between 1 and ' num2str(handles.nsets)];
      %             title = 'ERPLAB: geterpvaluesGUI inputs';
      %             errorfound(sprintf(msgboxText), title);
      %             return
      %       end
      %       if max(erpset)>handles.nsets
      %             msgboxText =  ['ERPset indexing out of range!\n\n'...
      %                   'You only have ' num2str(handles.nsets) ' ERPsets loaded on your ERPset Menu.'];
      %             title = 'ERPLAB: geterpvaluesGUI inputs';
      %             errorfound(sprintf(msgboxText), title);
      %             return
      %       end
      %       if min(erpset)<1
      %             msgboxText =  ['Invalid ERPset indexing!\n\n'...
      %                   'You may use any integer value between 1 and ' num2str(handles.nsets)];
      %             title = 'ERPLAB: geterpvaluesGUI inputs';
      %             errorfound(sprintf(msgboxText), title);
      %             return
      %       end
      
      checkerp = checkERPs(hObject, eventdata, handles);
      
      if checkerp
            return % problem was found
      end
      
      foption = 0; %from erpsets
else
      erpset = get(handles.listbox_erpnames, 'String');
      nline  = length(erpset);
      
      if nline==1
            msgboxText =  'You have to specify at least one erpset!';
            title = 'ERPLAB: geterpvaluesGUI() -> missing input';
            errorfound(msgboxText, title);
            return
      end
      
      listname = handles.listname;
      
      if isempty(listname) && nline>1
            
            BackERPLABcolor = [1 0.9 0.3];    % yellow
            question{1} = 'You have not saved your list.';
            question{2} = 'What would you like to do?';
            title       = 'Save List of ERPsets';
            oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
            set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
            button      = questdlg(question, title,'Save and Continue','Save As', 'Cancel','Save and Continue');
            set(0,'DefaultUicontrolBackgroundColor',oldcolor)
            
            if strcmpi(button,'Save As')
                  fullname = savelist(hObject, eventdata, handles);
                  listname = fullname;
                  set(handles.edit_filelist,'String', listname);
                  handles.listname = listname;
                  
                  % Update handles structure
                  guidata(hObject, handles);
                  return
            elseif strcmpi(button,'Save and Continue')
                  
                  fulltext = char(get(handles.listbox_erpnames,'String'));
                  listname = char(strtrim(get(handles.edit_filelist,'String')));
                  
                  if isempty(listname)
                        fullname = savelist(hObject, eventdata, handles);
                        listname = fullname;
                        set(handles.edit_filelist,'String', listname);
                  else
                        fid_list = fopen( listname , 'w');
                        for i=1:size(fulltext,1)-1
                              fprintf(fid_list,'%s\n', fulltext(i,:));
                        end
                        fclose(fid_list);
                  end
            elseif strcmpi(button,'Cancel') || strcmpi(button,'')
                  handles.output   = [];
                  handles.listname = [];
                  
                  % Update handles structure
                  guidata(hObject, handles);
                  return
            end
      end
      
      erpset = listname;
      foption = 1; % from list
end

xmin  = handles.xmin;
xmax  = handles.xmax;
fname = strtrim(get(handles.edit_fname, 'String'));

%
% Send to workspace
%
send2ws = get(handles.checkbox_send2ws, 'Value'); % 0:no; 1:yes
owfp    = handles.owfp;  % over write file permission
appendfile = 0;

if isempty(fname) && ~send2ws
      msgboxText =  'You have not yet written a file name for your outputs!';
      title = 'ERPLAB: geterpvaluesGUI() -> no file name';
      errorfound(msgboxText, title);
      return
elseif isempty(fname) && send2ws
      fname = 'no_save.no_save';
else
      [pu, fnameu, extu, versn] = fileparts(fname);
      if strcmp(extu,'')
            extu   = '.txt';
      end
      
      fname = fullfile(pu,[fnameu extu]);
      
      if exist(fname, 'file')~=0 && owfp==0
            question{1} = [fname ' already exists!'];
            question{2} = 'What would you like to do?';
            title       = 'ERPLAB: Overwriting Confirmation';            
            BackERPLABcolor = [1 0.9 0.3];    % yellow
            oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
            set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
            button      = questdlg(question, title,'Append','Overwrite', 'Cancel','Append');
            set(0,'DefaultUicontrolBackgroundColor',oldcolor)
            
            if strcmpi(button, 'Append')
                  appendfile = 1;
            elseif strcmpi(button, 'Overwrite')
                  appendfile = 0;
            else
                  return
            end
      end
end

binArraystr  = get(handles.edit_bins, 'String');
chanArraystr = get(handles.edit_channels, 'String');
latestr      = get(handles.edit_latency, 'String');

if ~strcmp(chanArraystr, '') && ~isempty(chanArraystr) && ...
            ~strcmp(fname, '') && ~isempty(fname) && ...
            ~strcmp(latestr, '') && ~isempty(latestr) && ...
            ~strcmp(binArraystr, '') && ~isempty(binArraystr)
      
      binArray   = str2num(binArraystr);
      chanArray  = str2num(chanArraystr);
      late       = str2num(latestr);
      nlate      = length(late);
      
      if length(late)==2
            if late(1)>=late(2)
                  msgboxText =  ['For latency range, lower time limit must be on the left.\n'...
                        'Additionally, lower latency limit must be at least 1/fs seconds\n'...
                        'lesser than the higher one.'];
                  title = 'ERPLAB: Bin-based epoch inputs';
                  errorfound(sprintf(msgboxText), title)
                  return
            end
      end
      
      polpeak    = [];
      sampeak    = [];
      coi        = 0; % ignore overlapped components
      locpeakrep = 0;
      frac       = [];
      fracmearep = 0;
      measure_option = get(handles.popupmenu_measurement, 'Value');
      areatype   = get(handles.popupmenu_areatype,'Value');  % 1=total ; 2=pos; 3=neg
      
      switch measure_option
            case 1  % instabl
                  if nlate~=1
                        msgboxText =  'You must define only one latency';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  moption = 'instabl';
                  fprintf('\nInstantaneous amplitude measurement in progress...\n');
            case 2  % meanbl
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  moption = 'meanbl';
                  fprintf('\nMean amplitude measurement in progress...\n');
            case 3  % peakampbl
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  moption = 'peakampbl';
                  polpeak = 2-get(handles.popupmenu_pol_amp,'Value');
                  sampeak = get(handles.popupmenu_samp_amp,'Value') - 1;
                  locpeakrep = 2-get(handles.popupmenu_locpeakreplacement,'Value');
                  fprintf('\nLocal peak measurement in progress...\n');
            case 4  % peaklatbl
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  moption = 'peaklatbl';
                  polpeak = 2-get(handles.popupmenu_pol_amp,'Value');
                  sampeak = get(handles.popupmenu_samp_amp,'Value') - 1;
                  locpeakrep = 2-get(handles.popupmenu_locpeakreplacement,'Value');
                  fprintf('\nLocal peak latency measurement in progress...\n');
            case 5  % fpeaklat
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  set(handles.text_fraca,'String', 'Fractional Peak')
                  moption = 'fpeaklat';
                  frac    = (get(handles.popupmenu_fraca,'Value') - 1)/100; % 0 to 1
                  polpeak = 2-get(handles.popupmenu_pol_amp,'Value');
                  sampeak = get(handles.popupmenu_samp_amp,'Value') - 1;
                  locpeakrep = 2-get(handles.popupmenu_locpeakreplacement,'Value');
                  fracmearep = 2-get(handles.popupmenu_fracreplacement,'Value');
                  fprintf('\nFractional Peak Latency measurement in progress...\n');
            case 6  % inte/area value (fixed latencies)
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  switch areatype
                        case 1
                              moption = 'areat';
                              fprintf('\nTotal area measurement in progress...\n');
                        case 2
                              moption = 'ninteg';
                              fprintf('\nNumerical integration in progress...\n');
                        case 3
                              moption = 'areap';
                              fprintf('\nPositive area measurement in progress...\n');
                        case 4
                              moption = 'arean';
                              fprintf('\nNegative area measurement in progress...\n');
                  end
                  
                  %                   if areatype==1 % total
                  %                         moption = 'areat';
                  %                         fprintf('\nTotal area measurement in progress...\n');
                  %                   elseif areatype==2
                  %                         moption = 'areap';
                  %                         fprintf('\nPositive area measurement in progress...\n');
                  %                   elseif areatype==3
                  %                         moption = 'arean';
                  %                         fprintf('\nNegative area measurement in progress...\n');
                  %                   else
                  %                         error('wrong area type.')
                  %                   end
            case 7   % inte/area value (auto latencies)
                  if nlate~=1
                        msgboxText =  'You must define only one latency';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  switch areatype
                        case 1
                              moption = 'areazt';
                              fprintf('\nTotal area measurement in progress...\n');
                        case 2
                              moption = 'nintegz';
                              fprintf('\nNumerical integration (automatic limits) in progress...\n');
                        case 3
                              moption = 'areazp';
                              fprintf('\nPositive area measurement (automatic limits) in progress...\n');
                        case 4
                              moption = 'areazn';
                              fprintf('\nNegative area measurement (automatic limits) in progress...\n');
                  end
                  
                  %                   if areatype==1 % total
                  %                         moption = 'areazt';
                  %                         fprintf('\nTotal area measurement (automatic limits) in progress...\n');
                  %                   elseif areatype==2
                  %                         moption = 'areazp';
                  %                         fprintf('\nPositive area measurement (automatic limits) in progress...\n');
                  %                   elseif areatype==3
                  %                         moption = 'areazn';
                  %                         fprintf('\nNegative area measurement (automatic limits) in progress...\n');
                  %                   else
                  %                         error('wrong area type.')
                  %                   end
            case 8   % fractional inte/area latency
                  if nlate~=2
                        msgboxText =  'You must define two latencies';
                        title = 'ERPLAB: Bin-based epoch inputs';
                        errorfound(sprintf(msgboxText), title)
                        return
                  end
                  
                  set(handles.text_fraca,'String', 'Fractional Area')
                  frac = (get(handles.popupmenu_fraca,'Value') - 1)/100; % 0 to 1
                  
                  switch areatype
                        case 1
                              moption = 'fareatlat';
                              fprintf('\nFractional Total Area Latency measurement in progress...\n');
                        case 2
                              moption = 'fninteglat';
                              fprintf('\nFractional Total Area Latency measurement in progress...\n');
                        case 3
                              moption = 'fareaplat';
                              fprintf('\nFractional Positive Area Latency measurement in progress...\n');
                              
                        case 4
                              moption = 'fareanlat';
                              fprintf('\nFractional Negative Area Latency measurement in progress...\n');
                        otherwise
                              error('wrong area type.')
                  end
                  
                  fracmearep = 1+ (-1)^(get(handles.popupmenu_fracreplacement,'Value')); % when 1 means 0, when 2 means 2
                  
                  %
                  %
                  %                   if areatype==1 % total
                  %                         moption = 'fareatlat';
                  %                         fprintf('\nFractional Total Area Latency measurement in progress...\n');
                  %                   elseif areatype==2
                  %                         moption = 'fareaplat';
                  %                         fprintf('\nFractional Positive Area Latency measurement in progress...\n');
                  %                   elseif areatype==3
                  %                         moption = 'fareanlat';
                  %                         fprintf('\nFractional Negative Area Latency measurement in progress...\n');
                  %                   else
                  %                         error('wrong area type.')
                  %                   end
                  
                  %             case 9
                  %                   if nlate~=2
                  %                         msgboxText =  'You must define two latencies';
                  %                         title = 'ERPLAB: Bin-based epoch inputs';
                  %                         errorfound(sprintf(msgboxText), title)
                  %                         return
                  %                   end
                  %
                  %                   moption = 'ninteg';
                  %                   fprintf('\nNumerical integration in progress...\n');
                  %             case 10
                  %                   if nlate~=1
                  %                         msgboxText =  'You must define only one latency';
                  %                         title = 'ERPLAB: Bin-based epoch inputs';
                  %                         errorfound(sprintf(msgboxText), title)
                  %                         return
                  %                   end
                  %                   moption = 'nintegz';
                  %                   fprintf('\nNumerical integration (automatic limits) in progress...\n');
      end
      
      %
      % Baseline range
      %
      blrnames = {'none','pre','post','all'};
      indxblr  = get(handles.popupmenu_baseliner, 'Value');
      
      if indxblr<5
            blc = blrnames{indxblr};
      else
            blcnumx = str2num(get(handles.edit_custombr,'String'));
            
            if isempty(blcnumx) %char
                  msgboxText = [ 'Invalid Baseline range!\n'...
                        'Please enter a numeric range'];
                  title = 'ERPLAB: geterpvaluesGUI() -> invalid input';
                  errorfound(sprintf(msgboxText), title);
                  return
            else %num
                  
                  blcnum = blcnumx/1000;               % from msec to secs  03-28-2009
                  
                  %
                  % Check & fix baseline range
                  %
                  if blcnum(1)<xmin
                        blcnum(1) = xmin;
                  end
                  if blcnum(2)>xmax
                        blcnum(2) = xmax;
                  end
                  
                  blc = blcnum*1000;  % sec to msec
            end
      end
      
      %
      % Format output
      %
      foutput = get(handles.popupmenu_formatout, 'Value') - 1;
      
      %
      % Measure's label
      %
      mlabel = get(handles.edit_label_mea,'String');
      mlabel = strtrim(mlabel);
      mlabel = strrep(mlabel, ' ', '_');
      dig   = get(handles.popupmenu_precision, 'Value');
      binlabop = get(handles.checkbox_binlabel,'Value'); % bin label option for table      
      inclate = get(handles.checkbox_include_used_latencies, 'Value');
      
      %####################################################################
      %#############                                          #############
      %#############              OUTCOME                     #############
      %#############                                          #############
      %####################################################################
      %       foption            : input file option, 1=from HD, 0=from erpset menu
      %       erpset             : erpset names or indices (depends on foption)
      %       fname              :
      %       late               : latency(ies) for measurement
      %       binArray           : bin index(ices) for measurement
      %       chanArray          : chan index(ices) for measurement
      %       moption            : type of measurement --> instabl, meanbl, peakampbl, peaklatbl, area, etc...
      %       coi                : reserved
      %       dig                : numeric precision
      %       blc                : base line reference
      %       binlabop           : 0: bin number as bin label, 1: bin descriptor as bin label for table.
      %       polpeak            : local peak polarity
      %       sampeak            : number of samples (one-side) for local peak detection criteria
      %       locpeakrep
      %       send2ws
      %       appendfile
      %       foutput
      %       frac
      %       mlabel
      
      outstr = {foption, erpset, fname, late, binArray, chanArray, moption,...
            coi, dig, blc, binlabop, polpeak, sampeak, locpeakrep, frac, fracmearep, send2ws, appendfile, foutput, mlabel, inclate};
      handles.output = outstr;
      
      % Update handles structure
      guidata(hObject, handles);
      uiresume(handles.figure1);
else
      msgboxText =  'Please fill-up required fields';
      title = 'ERPLAB: geterpvaluesGUI() -> missing information';
      errorfound(msgboxText, title);
      return
end

%--------------------------------------------------------------------------
function edit_channels_Callback(hObject, eventdata, handles)

channnums =  str2num(get(handles.edit_channels,'String'));

if ~isempty(channnums)
      chanstr = get(handles.popupmenu_channels, 'String');
      
      if max(channnums)<=length(chanstr)
            set(handles.popupmenu_channels, 'Value',max(channnums));
      end
end

%--------------------------------------------------------------------------
function edit_channels_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_channels_Callback(hObject, eventdata, handles)

numch   = get(hObject, 'Value');

nums = get(handles.edit_channels, 'String');
nums = [nums ' ' num2str(numch)];
set(handles.edit_channels, 'String', nums);

%--------------------------------------------------------------------------
function popupmenu_channels_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
% function checkbox_catch_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_precision_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_precision_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

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
function listbox_erpnames_Callback(hObject, eventdata, handles)

fulltext  = get(handles.listbox_erpnames, 'String');
indxline  = length(fulltext);

currlineindx = get(handles.listbox_erpnames, 'Value');

%--------------------------------------------------------------------------
function listbox_erpnames_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function button_adderpset_Callback(hObject, eventdata, handles)

[erpfname, erppathname] = uigetfile({  '*.erp','ERPLAB-files (*.erp)'; ...
      '*.mat','Matlab (*.mat)'; ...
      '*.*',  'All Files (*.*)'}, ...
      'Select an edited file', ...
      'MultiSelect', 'on');

if isequal(erpfname,0)
      disp('User selected Cancel')
      return
else
      try
            %
            % test current directory
            %
            changecd(erppathname)
            
            if ~iscell(erpfname)
                  erpfname = {erpfname};
            end
            
            nerpn = length(erpfname);
            
            for i=1:nerpn
                  newline  = fullfile(erppathname, erpfname{i});
                  currline = get(handles.listbox_erpnames, 'Value');
                  fulltext = get(handles.listbox_erpnames, 'String');
                  
                  indxline = length(fulltext);
                  
                  if i==1 && length(fulltext)-1==0  % put this one on the list
                        ERP1 = load(newline, '-mat');
                        ERP = ERP1.ERP;
                        
                        if ~iserpstruct(ERP)
                              error('')
                        end
                        handles.srate = ERP.srate;
                        %
                        % Prepare List of current Channels and bins
                        %
                        preparelists(ERP, hObject, eventdata, handles);
                  end
                  
                  if currline==indxline
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
                  
                  fulltext{currline} = newline;
                  set(handles.listbox_erpnames, 'String', fulltext)
            end
            
            handles.listname = [];
            indxline = length(fulltext);
            handles.indxline = indxline;
            handles.fulltext = fulltext;
            set(handles.button_savelistas, 'Enable','on')
            set(handles.edit_filelist,'String','');
            
            % Update handles structure
            guidata(hObject, handles);
      catch
            msgboxText =  'A file you are attempting to load is not an ERPset!';
            title = 'ERPLAB: geterpvaluesGUI2 inputs';
            errorfound(msgboxText, title);
            handles.listname = [];
            set(handles.button_savelist, 'Enable','off')
            
            % Update handles structure
            guidata(hObject, handles);
      end
end

%--------------------------------------------------------------------------
function button_delerpset_Callback(hObject, eventdata, handles)

fulltext = get(handles.listbox_erpnames, 'String');
indxline = length(fulltext);
fulltext = char(fulltext); % string matrix
currline = get(handles.listbox_erpnames, 'Value');

if currline>=1 && currline<indxline
      
      fulltext(currline,:) = [];
      fulltext = cellstr(fulltext); % cell string
      
      if length(fulltext)>1 % put this one first on the list
            newline = fulltext{1};
            ERP1 = load(newline, '-mat');
            ERP = ERP1.ERP;
            %
            % Prepare List of current Channels and bins
            %
            preparelists(ERP, hObject, eventdata, handles);
      else
            preparelists([], hObject, eventdata, handles);
      end
      
      set(handles.listbox_erpnames, 'String', fulltext);
      listbox_erpnames_Callback(hObject, eventdata, handles)
      handles.fulltext = fulltext;
      indxline = length(fulltext);
      handles.listname = [];
      set(handles.edit_filelist,'String','');
      
      % Update handles structure
      guidata(hObject, handles);
else
      set(handles.button_savelistas, 'Enable','off')
end

%--------------------------------------------------------------------------
function edit_bins_Callback(hObject, eventdata, handles)

binnums =  str2num(get(handles.edit_bins,'String'));

if ~isempty(binnums)
      binstr = get(handles.popupmenu_bins, 'String');
      
      if max(binnums)<=length(binstr)
            set(handles.popupmenu_bins, 'Value',max(binnums));
      end
end

%--------------------------------------------------------------------------
function edit_bins_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_bins_Callback(hObject, eventdata, handles)

numbin   = get(hObject, 'Value');
nums = get(handles.edit_bins, 'String');
nums = [nums ' ' num2str(numbin)];
set(handles.edit_bins, 'String', nums);

%--------------------------------------------------------------------------
function popupmenu_bins_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_custom_Callback(hObject, eventdata, handles)

blcstr = get(handles.edit_custom,'String');
blc = str2num(blcstr);

if isempty(blc)
      msgboxText =  'Invalid baseline! You have to enter 2 numeric values, in ms.';
      title = 'ERPLAB: geterpvalues GUI invalid baseline input';
      errorfound(msgboxText, title);
      return
else
      if size(blc,1)>1 || size(blc,2)~=2
            msgboxText =  'Invalid baseline! You have to enter 2 numeric values, in ms.';
            title = 'ERPLAB: geterpvalues GUI invalid baseline input';
            errorfound(msgboxText, title);
            return
      end
end

%--------------------------------------------------------------------------
function edit_custom_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function button_savelistas_Callback(hObject, eventdata, handles)

fulltext = char(get(handles.listbox_erpnames,'String'));

if length(fulltext)>1
      fullname = savelist(hObject, eventdata, handles);
      
      if isempty(fullname)
            return
      end
      
      set(handles.edit_filelist, 'String', fullname )
      set(handles.button_savelist, 'Enable', 'on')
      handles.listname = fullname;
      
      % Update handles structure
      guidata(hObject, handles);
else
      set(handles.button_savelistas,'Enable','off')
      msgboxText =  'You have not specified any ERPset!';
      title = 'ERPLAB: averager GUI few inputs';
      errorfound(msgboxText, title);
      set(handles.button_savelistas,'Enable','on')
      return
end

%--------------------------------------------------------------------------
function button_loadlist_Callback(hObject, eventdata, handles)

[listname, lispath] = uigetfile({  '*.txt','Text File (*.txt)'; ...
      '*.*',  'All Files (*.*)'}, ...
      'Select an edited list', ...
      'MultiSelect', 'off');

if isequal(listname,0)
      disp('User selected Cancel')
      return
else
      fullname = fullfile(lispath, listname);
      disp(['For erpset list user selected  <a href="matlab: open(''' fullname ''')">' fullname '</a>'])
end

fid_list   = fopen( fullname );
formcell = textscan(fid_list, '%[^\n]','CommentStyle','#', 'whitespace', '');
lista = formcell{:};

% extra line forward
lista   = cat(1, lista, {'new erpset'});
lentext = length(lista);
fclose(fid_list);

if lentext>1
      %         try
      filereadin = strtrim(lista{1});
      ERP1 = load(filereadin, '-mat');
      ERP = ERP1.ERP;
      
      if ~iserpstruct(ERP)
            error('')
      end
      
      handles.srate = ERP.srate;
      %
      % Prepare List of current Channels and bins
      %
      preparelists(ERP, hObject, eventdata, handles);
      
      set(handles.listbox_erpnames,'String',lista);
      set(handles.edit_filelist,'String',fullname);
      listname = fullname;
      handles.listname = listname;
      set(handles.button_savelistas, 'Enable','on')
      
      % Update handles structure
      guidata(hObject, handles);
      %         catch
      %                 msgboxText =  'This list is anything but an ERPset list!';
      %                 title = 'ERPLAB: geterpvaluesGUI inputs';
      %                 errorfound(msgboxText, title)
      %                 handles.listname = [];
      %                 set(handles.button_savelist, 'Enable','off')
      %
      %                 % Update handles structure
      %                 guidata(hObject, handles);
      %         end
else
      msgboxText =  'This list is empty!';
      title = 'ERPLAB: geterpvaluesGUI inputs';
      errorfound(msgboxText, title);
      handles.listname = [];
      set(handles.button_savelist, 'Enable','off')
      
      % Update handles structure
      guidata(hObject, handles);
end

%--------------------------------------------------------------------------
function xxx_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_erpset_Callback(hObject, eventdata, handles)

[checkerp erp_ini] = checkERPs(hObject, eventdata, handles);

if checkerp
      return % problem was found
end

ALLERP = handles.ALLERP;
preparelists(ALLERP(erp_ini), hObject, eventdata, handles);


%--------------------------------------------------------------------------
function [checkerp erp_ini]= checkERPs(hObject, eventdata, handles)

checkerp  = 0; % no problem
ALLERP = handles.ALLERP;
nerp   = handles.nsets;

%
% Read first ERPset
%
if get(handles.radiobutton_erpset, 'Value')==1;
      indexerp = unique(str2num(get(handles.edit_erpset, 'String')));
      if isempty(indexerp)
            checkerp  = 1;
            return
      end
      erp_ini = indexerp(1);
else
      erp_ini = 1;
end
if max(indexerp)>nerp
      msgboxText =  ['ERPset indexing out of range!\n\n'...
            'You only have ' num2str(nerp) ' ERPsets loaded on your ERPset Menu.'];
      title = 'ERPLAB: geterpvaluesGUI inputs';
      errorfound(sprintf(msgboxText), title);
      checkerp  = 1;
      return
end
if min(indexerp)<1
      msgboxText =  ['Invalid ERPset indexing!\n\n'...
            'You may use any integer value between 1 and ' num2str(nerp)];
      title = 'ERPLAB: geterpvaluesGUI inputs';
      errorfound(sprintf(msgboxText), title);
      checkerp  = 1;
      return
end

nerp2      = length(indexerp);

for k=1:nerp2
      kbin(k) = ALLERP(indexerp(k)).nbin;
      kchan(k) = ALLERP(indexerp(k)).nchan;
end

bintest  = length(unique(kbin));
chantest = length(unique(kchan));

if bintest>1
      fprintf('Detail:\n')
      fprintf('-------\n')
      
      for j=1:nerp2
            fprintf('Erpset #%g = %g bins\n', indexerp(j),ALLERP(indexerp(j)).nbin)
      end
      msgboxText =  ['Number of bins across ERPsets is different!\n\n'...
            'See detail at command window.\n'];
      title = 'ERPLAB: geterpvaluesGUI inputs';
      errorfound(sprintf(msgboxText), title);
      checkerp  = 1;
      return
else
      nbin = unique(kbin);
end
if chantest>1
      fprintf('Detail:\n')
      fprintf('-------\n')
      
      for j=1:nerp2
            fprintf('Erpset #%g = %g channnels\n', indexerp(j),ALLERP(indexerp(j)).nchan)
      end
      msgboxText =  ['Number of channels across ERPsets is different!\n\n'...
            'See detail at command window.\n'];
      title = 'ERPLAB: geterpvaluesGUI inputs';
      errorfound(sprintf(msgboxText), title);
      checkerp  = 1;
      return
end

errorlabel = 0;
kbinlabel  = cell(1);

for k=1:nerp2
      kbinlabel{k} = [ALLERP(indexerp(k)).bindescr{:}];
      if k>1
            if ~strcmpi(kbinlabel{k},kbinlabel{k-1})
                  errorlabel = 1;
                  break
            end
      end
end
if errorlabel==1
      fprintf('Detail:\n')
      fprintf('-------\n')
      
      for j=1:nerp2
            fprintf('Erpset #%g :\n', indexerp(j));
            fprintf('\t%s\n', ALLERP(indexerp(j)).bindescr{:});
      end
      msgboxText =  ['Bin labels across ERPsets are different!\n'...
            '(See detail at command window)\n\n'...
            'What would you like to do?'];
      BackERPLABcolor = [1 0.9 0.3];    % yellow
      %question{1} = 'You have not saved your list.';
      %question{2} = 'What would you like to do?';
      title       = 'Save List of ERPsets';
      oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
      set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
      button      = questdlg(sprintf(msgboxText), title,'Cancel','Terminate', 'Continue', 'Continue');
      set(0,'DefaultUicontrolBackgroundColor',oldcolor)
      
      if strcmpi(button,'Continue')
            checkerp  = 0;
            return
      elseif strcmpi(button,'Cancel') || strcmpi(button,'')
            checkerp  = 1;
            return
      elseif strcmpi(button,'Terminate')
            
            handles.output = [];            
            % Update handles structure
            guidata(hObject, handles);
            uiresume(handles.figure1);
      end
end

%--------------------------------------------------------------------------
function edit_erpset_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function radiobutton_erpset_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.edit_erpset,'Enable','on')
      set(handles.radiobutton_folders,'Value',0)
      set(handles.listbox_erpnames,'Enable','off')
      set(handles.button_adderpset,'Enable','off')
      set(handles.button_delerpset,'Enable','off')
      set(handles.button_savelist,'Enable','off')
      set(handles.button_clearfile,'Enable','off')
      set(handles.button_savelistas,'Enable','off')
      set(handles.button_loadlist,'Enable','off')
      set(handles.edit_filelist,'Enable','off')
      set(handles.pushbutton_flush,'Enable','off')
else
      set(hObject,'Value',1)
end

%--------------------------------------------------------------------------
function radiobutton_folders_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
      set(handles.radiobutton_erpset,'Value',0)
      set(handles.edit_erpset,'Enable','off')
      set(handles.listbox_erpnames,'Enable','on')
      set(handles.button_adderpset,'Enable','on')
      set(handles.button_delerpset,'Enable','on')
      
      if ~isempty(get(handles.edit_filelist,'String'))
            set(handles.button_savelist,'Enable','on')
            set(handles.button_clearfile,'Enable','on')
      end
      
      set(handles.button_savelistas,'Enable','on')
      set(handles.button_loadlist,'Enable','on')
      set(handles.edit_filelist,'Enable','on')
      set(handles.pushbutton_flush,'Enable','on')
else
      set(hObject,'Value',1)
end

%--------------------------------------------------------------------------
function fullname = savelist(hObject, eventdata, handles)

fullname = '';
fulltext = char(get(handles.listbox_erpnames,'String'));
%
% Save OUTPUT file
%
[filename, filepath, filterindex] = uiputfile({'*.txt';'*.dat';'*.*'},'Save erpset list as');

if isequal(filename,0)
      disp('User selected Cancel')
      return
else
      
      [px, fname, ext, versn] = fileparts(filename);
      
      if strcmp(ext,'')
            if filterindex==1 || filterindex==3
                  ext   = '.txt';
            else
                  ext   = '.dat';
            end
      end
      
      fname = [ fname ext];
      fullname = fullfile(filepath, fname);
      disp(['To Save erpset list, user selected ', fullname])
      
      fid_list   = fopen( fullname , 'w');
      
      for i=1:size(fulltext,1)-1
            fprintf(fid_list,'%s\n', fulltext(i,:));
      end
      
      fclose(fid_list);
end

% -------------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function preparelists(ERPi, hObject, eventdata, handles)

%
% Prepare List of current Channels and bins
%
if ~isempty(ERPi)
      
      ERPi   = ERPi(1);
      listch = [];
      nchan  = ERPi.nchan; %
      nbin   = ERPi.nbin; %
      xmin   = ERPi.xmin; %
      xmax   = ERPi.xmax; %
      srate  = ERPi.srate; %
      
      if isempty(ERPi.chanlocs)
            for e=1:nchan
                  ERPi.chanlocs(e).labels = ['Ch' num2str(e)];
            end
      end
      for ch =1:nchan
            listch{ch} = [num2str(ch) ' = ' ERPi.chanlocs(ch).labels ];
      end
      
      %
      % Prepare List of current Bins
      %
      listb = [];
      
      for b=1:nbin
            listb{b}= ['BIN' num2str(b) ' = ' ERPi.bindescr{b} ];
      end
      
      memoryinput = handles.memoryinput;
      
      if ~isempty(memoryinput)
            binArray  = memoryinput{5};
            chanArray = memoryinput{6};
            selchan   = chanArray(chanArray>=1 & chanArray<=nchan);
            selbin    = binArray(binArray>=1 & binArray<=nbin);
      else
            selchan = 1:nchan;
            selbin  = 1:nbin;
      end
      
      set(handles.popupmenu_bins,'String', listb)
      set(handles.edit_bins,'String', vect2colon(selbin, 'Delimiter','no'))
      set(handles.popupmenu_channels,'String', listch)
      set(handles.edit_channels,'String', vect2colon(selchan, 'Delimiter','no'))
      drawnow
else
      nchan = 0;
      nbin  = 0;
      xmin  = [];
      xmax  = [];
      srate = [];
      set(handles.popupmenu_channels,'String', 'No Chans')
      set(handles.popupmenu_bins,'String', 'No Bins')
      set(handles.edit_bins,'String', '')
      set(handles.edit_channels,'String', '')
      drawnow
end

handles.nchan = nchan;
handles.nbin  = nbin;
handles.xmin  = xmin;
handles.xmax  = xmax;
handles.srate = srate;

% Update handles structure
guidata(hObject, handles);

% -------------------------------------------------------------------------
function checkbox_binlabel_Callback(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function checkbox_binlabel_CreateFcn(hObject, eventdata, handles)

% -------------------------------------------------------------------------
function pushbutton_run_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function button_savelist_Callback(hObject, eventdata, handles)
fulltext = char(strtrim(get(handles.listbox_erpnames,'String')));

if length(fulltext)>1
      
      fullname = get(handles.edit_filelist, 'String');
      
      if ~strcmp(fullname,'')
            
            fid_list   = fopen( fullname , 'w');
            
            for i=1:size(fulltext,1)
                  fprintf(fid_list,'%s\n', fulltext(i,:));
            end
            
            fclose(fid_list);
            handles.listname = fullname;
            
            % Update handles structure
            guidata(hObject, handles);
            disp(['Saving equation list at <a href="matlab: open(''' fullname ''')">' fullname '</a>'])
      else
            button_savelistas_Callback(hObject, eventdata, handles)
            return
      end
else
      set(handles.button_savelistas,'Enable','off')
      msgboxText =  'You have not written any formula yet!';
      title = 'ERPLAB: chanoperGUI few inputs';
      errorfound(msgboxText, title);
      set(handles.button_savelistas,'Enable','on')
      return
end

%--------------------------------------------------------------------------
function button_clearfile_Callback(hObject, eventdata, handles)

set(handles.edit_filelist,'String','');
set(handles.button_savelist, 'Enable', 'off')
handles.listname = [];
% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------------
function edit_filelist_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_filelist_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_pol_amp_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_pol_amp_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_samp_amp_Callback(hObject, eventdata, handles)

srate = handles.srate;
pnts = get(handles.popupmenu_samp_amp,'Value')-1;
if isempty(srate)
      msecstr = sprintf('pnts ( ? ms)');
else
      msecstr = sprintf('pnts (%4.1f ms)', (pnts/srate)*1000);
end
set(handles.text_samp,'String',msecstr)

%--------------------------------------------------------------------------
function popupmenu_samp_amp_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_measurement_Callback(hObject, eventdata, handles)
%
% Name & version
%
meamenu  = get(handles.popupmenu_measurement, 'String');
areatype = get(handles.popupmenu_areatype,'Value');

currentm = get(handles.popupmenu_measurement, 'Value');
formatout = get(handles.popupmenu_formatout,'Value');

%
% suggests measurement label
%
% if formatout==2
%       switch currentm
%
%             case 1
%                   meatxt = 'insta_amp';
%             case 2
%                   meatxt = 'mean_amp';
%             case 3
%                   meatxt = 'peak_amp';
%             case 4
%                   meatxt = 'peak_lat';
%             case 5
%                   meatxt = 'frac_peak_lat';
%             case 6
%                   if areatype==1
%                         meatxt = 'area_2L';
%                   elseif areatype==2
%                         meatxt = 'integra_2L';
%                   elseif areatype==3
%                         meatxt = 'pos_area_2L';
%                   elseif areatype==4
%                         meatxt = 'neg_area_2L';
%                   end
%             case 7
%                   if areatype==1
%                         meatxt = 'area_auto';
%                   elseif areatype==2
%                         meatxt = 'integra_auto';
%                   elseif areatype==3
%                         meatxt = 'pos_area_auto';
%                   elseif areatype==4
%                         meatxt = 'neg_area_auto';
%                   end
%             case 8
%                   meatxt = 'frac_area_lat';
%       end
%       set(handles.edit_label_mea,'String', meatxt );
% end

version  = geterplabversion;
set(handles.figure1,'Name', ['ERPLAB ' version '   -   ERP Measurements GUI   -   ' meamenu{currentm}])


%
%  NEW MENU
%

% 1 = 'Instantaneous amplitude',
% 2 = 'Mean amplitude between two fixed latencies',...
% 3 = 'Peak amplitude'
% 4 = 'Peak latency'
% 5 = 'Fractional Peak latency',...
% 6 = 'Numerical integration/Area between two fixed latencies'
% 7 = 'Numerical integration/Area between two (automatically detected) zero-crossing latencies'...
% 8 = 'Fractional Area latency'

switch currentm
      
      case 1 % 'Instantaneous amplitude'
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','at latency (just one)');
            set(handles.popupmenu_areatype,'Enable','off')
            
      case {2,6} % mean, area, integral between fixed latencies
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            if currentm==6
                  set(handles.popupmenu_areatype,'Enable','on')
            else
                  set(handles.popupmenu_areatype,'Enable','off')
            end
            %         case 5
            %                 menupeakoff(hObject, eventdata, handles)
            %                 set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            
      case {3,4} % 'Peak amplitude', 'Peak latency'
            menupeakon(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.popupmenu_areatype,'Enable','off')
            set(handles.popupmenu_fracreplacement, 'String', {'fractional absolute peak','"not a number" (NaN)'});
            %         case 3
            %                 menupeakon(hObject, eventdata, handles)
            %                 set(handles.uipanel_inputlat, 'Title','between latencies (2)');
      case 5 % 'Fractional Peak latency'
            menupeakon(hObject, eventdata, handles)
            menufareaon(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.text_fraca,'String', 'Fractional Peak')
            set(handles.popupmenu_areatype,'Enable','off')
            %'fpeaklat'
            
      case {7} % area, integral automatic limits
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','seed latency (just one)');
            if currentm==7
                  set(handles.popupmenu_areatype,'Enable','on')
            else
                  set(handles.popupmenu_areatype,'Enable','off')
            end
      case 8 % 'Fractional Area latency'
            menupeakoff(hObject, eventdata, handles)
            menufareaon(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.text_fraca,'String', 'Fractional Area')
            set(handles.popupmenu_areatype,'Enable','on')
            set(handles.popupmenu_fracreplacement, 'String', {'show error message','"not a number" (NaN)'});
      otherwise % 'test'
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
end

%meatxt    = get(handles.edit_label_mea,'String')














%--------------------------------------------------------------------------
function popupmenu_measurement_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_locpeakreplacement_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_locpeakreplacement_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function uipanel9_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel1_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel2_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function pushbutton_cancel_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel_inputlat_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel4_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel6_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel8_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel12_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function uipanel13_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function radiobutton_erpset_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function radiobutton_folders_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function setall(hObject, eventdata, handles)

ALLERP   = handles.ALLERP;
% xmin     = handles.xmin;
% xmax     = handles.xmax;
% owfp     = handles.owfp;

if isstruct(ALLERP)
      nsets    = length(ALLERP);
      %
      % Prepare List of current Channels and bins
      %
      preparelists(ALLERP(1), hObject, eventdata, handles);
else
      nsets = 0;
      %
      % Prepare List of current Channels and bins
      %
      preparelists([], hObject, eventdata, handles);
end

set(handles.popupmenu_samp_amp,'String',cellstr(num2str([0:40]')))
set(handles.popupmenu_precision,'String', num2str([1:6]'))
% set(handles.popupmenu_precision, 'Value', 3);

%
% Measurement types
%
% 1  --> 'Instantaneous amplitude'
% 2  --> 'Mean amplitude between two fixed latencies'
% 3  --> 'Peak amplitude'
% 4  --> 'Peak latency'
% 5  --> 'Fractional Peak latency'
% 6  --> 'Area under the curve between two fixed latencies'
% 7  --> 'Area under the curve between two (automatically detected) zero-crossing latencies'
% 8  --> 'Fractional Area latency'
% 9  --> 'Numerical integration between two fixed latencies'
% 10 --> 'Numerical integration between two (automatically detected) zero-crossing latencies'

% measurearray = {'Instantaneous amplitude','Mean amplitude between two fixed latencies',...
%       'Peak amplitude','Peak latency','Fractional Peak latency',...
%       'Area under the curve between two fixed latencies',...
%       'Area under the curve between two (automatically detected) zero-crossing latencies',...
%       'Fractional Area latency',...
%       'Numerical integration between two fixed latencies',...
%       'Numerical integration between two (automatically detected) zero-crossing latencies'};


%
%  NEW MENU
%

% 1 = 'Instantaneous amplitude',
% 2 = 'Mean amplitude between two fixed latencies',...
% 3 = 'Peak amplitude'
% 4 = 'Peak latency'
% 5 = 'Fractional Peak latency',...
% 6 = 'Numerical integration/Area between two fixed latencies'
% 7 = 'Numerical integration/Area between two (automatically detected) zero-crossing latencies'...
% 8 = 'Fractional Area latency'

%
% New Are type menu
%
% 1 = 'Rectified area (negative values become positive)'
% 2 = 'Numerical integration (negative substracted from positive)'
% 3 = 'Only positive area'
% 4 = 'Only negative area'
%

measurearray = {'Instantaneous amplitude','Mean amplitude between two fixed latencies',...
      'Peak amplitude','Peak latency','Fractional Peak latency',...
      'Numerical integration/Area between two fixed latencies',...
      'Numerical integration/Area between two (automatically detected) zero-crossing latencies'...
      'Fractional Area latency'};

set(handles.popupmenu_measurement, 'String', measurearray);
set(handles.popupmenu_locpeakreplacement, 'String', {'absolute peak','"not a number" (NaN)','show error message'});
set(handles.popupmenu_fracreplacement, 'String', {'closest value','"not a number" (NaN)','show error message'});

%
% Baseline reference
%
measurearray = {'None','Pre','Post','Whole','Custom'};
set(handles.popupmenu_baseliner, 'String', measurearray);

%
% Output style
%
styleout = {'One ERPset per line (wide format)', 'One measurement per line (long format)'};
set(handles.popupmenu_formatout, 'String', styleout);

%
% Type of Area
%
% areatype = {'Total area', 'Only positive area', 'Only negative area'};
areatype = {'Rectified area (negative values become positive)', 'Numerical integration (area for negatives substracted from area for positives)',...
      'Area for positive waveforms (negative values will be zeroed)', 'Area for negative waveforms (positive values will be zeroed)'};
set(handles.popupmenu_areatype, 'String', areatype);

%
% GUI's working memory
%
memoryinput = handles.memoryinput;

if ~isempty(memoryinput)
      optioni    = memoryinput{1}; %1 means from hard drive, 0 means from erpsets menu
      erpset     = memoryinput{2}; % indices of erpset or filename of list of erpsets
      fname      = memoryinput{3};
      latency    = memoryinput{4};
      binArray   = memoryinput{5};
      chanArray  = memoryinput{6};
      op         = memoryinput{7}; % option: type of measurement ---> instabl, meanbl, peakampbl, peaklatbl, area, areaz, or errorbl.
      coi        = memoryinput{8};
      dig        = memoryinput{9};
      blc        = memoryinput{10};
      binlabop   = memoryinput{11}; % 0: bin# as bin label for table, 1 bin label
      polpeak    = memoryinput{12}; % local peak polarity
      sampeak    = memoryinput{13}; % number of samples (one-side) for local peak detection criteria
      locpeakrep = memoryinput{14}; % 1 abs peak , 0 Nan
      frac       = memoryinput{15};
      fracmearep = memoryinput{16}; % memoryinput{19}; NaN
      send2ws    = memoryinput{17}; % 1 send to ws, 0 dont do
      foutput    = memoryinput{18}; % 1 = 1 measurement per line; 0 = 1 erpset per line
      mlabel     = memoryinput{19};
      inclate    = memoryinput{20};
      
      if isempty(sampeak)
            sampeak = 3;
      end      
else
      optioni    = 1; %1 means from hard drive, 0 means from erpsets menu
      erpset     = 1; % indices of erpset or filename of list of erpsets
      fname      = '';
      latency    = 0;
      binArray   = 1;
      chanArray  = 1;
      op         = 'instabl'; % option: type of measurement ---> instabl, meanbl, peakampbl, peaklatbl, area, areaz, or errorbl.
      coi        = 0; % ignore overlapped components
      dig        = 3;
      blc        = 'pre';
      binlabop   = 0; % 0: bin# as bin label for table, 1 bin label
      polpeak    = 1; % local peak polarity
      sampeak    = 3; % number of samples (one-side) for local peak detection criteria
      locpeakrep = 1; % 1 abs peak , 0 Nan
      send2ws    = 0; % 1 send to ws, 0 dont do
      foutput    = 1; % 1 = 1 measurement per line; 0 = 1 erpset per line
      mlabel     = '';
      inclate    = 0;
      fracmearep = 1; %NaN
end

% 1  --> 'Instantaneous amplitude'
% 2  --> 'Mean amplitude between two fixed latencies'
% 3  --> 'Peak amplitude'
% 4  --> 'Peak latency'
% 5  --> 'Fractional Peak latency'
% 6  --> 'Area under the curve between two fixed latencies'
% 7  --> 'Area under the curve between two (automatically detected) zero-crossing latencies'
% 8  --> 'Fractional Area latency'
% 9  --> 'Numerical integration between two fixed latencies'
% 10 --> 'Numerical integration between two (automatically detected) zero-crossing latencies'

% {'Instantaneous amplitude','Mean amplitude between two fixed latencies',...
%       'Peak amplitude','Peak latency','Fractional Peak latency',...
%       'Area under the curve between two fixed latencies',...
%       'Area under the curve between two (automatically detected) zero-crossing latencies',...
%       'Fractional Area latency',...
%       'Numerical integration between two fixed latencies',...
%       'Numerical integration between two (automatically detected) zero-crossing latencies'};


%
%  NEW MENU (indxmea)
%

% 1 = 'Instantaneous amplitude',
% 2 = 'Mean amplitude between two fixed latencies',...
% 3 = 'Peak amplitude'
% 4 = 'Peak latency'
% 5 = 'Fractional Peak latency',...
% 6 = 'Numerical integration/Area between two fixed latencies'
% 7 = 'Numerical integration/Area between two (automatically detected) zero-crossing latencies'...
% 8 = 'Fractional Area latency'

%
% New Are type menu (areatype)
%
% 1 = 'Rectified area (negative values become positive)'
% 2 = 'Numerical integration (negative substracted from positive)'
% 3 = 'Only positive area'
% 4 = 'Only negative area'
%

%
% option #s  (indxmeaX)
%
% 1  = 'instabl'
% 2  = 'meanbl'
% 3  = 'peakampbl'
% 4  = 'peaklatbl'
% 5  = 'fpeaklat'
% 6  = 'areat'
% 7  = 'areap'
% 8  = 'arean'
% 9  = 'areazt'
% 10 = 'areazp'
% 11 = 'areazn'
% 12 = 'fareatlat'
% 13 = 'fninteglat'
% 14 = 'fareaplat'
% 15 = 'fareanlat'
% 16 = 'ninteg'
% 17 = 'nintegz'


[tfm indxmeaX] = ismember({op}, {'instabl', 'meanbl', 'peakampbl', 'peaklatbl', 'fpeaklat',...
      'areat', 'areap', 'arean','areazt','areazp','areazn','fareatlat', 'fninteglat',...
      'fareaplat','fareanlat', 'ninteg','nintegz' } );

%
% fix index for menu
%
areatype=1; % 1=total; 2=integral; 3=pos; 4= neg
fracmenuindex = 2-fracmearep;

if ismember(indxmeaX,[6 7 8 16])
      indxmea = 6;
      areatype = find(indxmeaX==[6 16 7 8]);  % 1,2,3,4
elseif ismember(indxmeaX,[9 10 11 17])
      areatype = find(indxmeaX==[9 17 10 11]);  % 1,2,3,4
      indxmea = 7;
elseif ismember(indxmeaX,[12 13 14 15])
      areatype = find(indxmeaX==[12 13 14 15]);  % 1,2,3,4
      indxmea = 8;
      fracmenuindex = round(2^(fracmearep/2)); % when 0 means 1, when 2 means 2;
else
      indxmea = indxmeaX;
end

if ischar(blc)
      [tfm indxblc] = ismember({blc}, {'none', 'pre', 'post', 'whole', 'all'} );
      
      if indxblc == 5
            indxblc = 4;
      elseif indxblc==0
            indxblc = 5;
      end
else
      indxblc = NaN;
end

%
% Type of output
%
% 1 = one measurement per line; 0 = one erpset per line
%
if foutput==0
      set(handles.popupmenu_formatout, 'Value', 1);
      
      %       set(handles.radiobutton_f0_1erp_per_line,'Value',1)
      %       set(handles.radiobutton_f1_1mea_per_line,'Value',0)
      set(handles.edit_label_mea,'Enable', 'off')
      set(handles.checkbox_include_used_latencies, 'Enable', 'off');
else
      set(handles.popupmenu_formatout, 'Value', 2);
      
      %       set(handles.radiobutton_f0_1erp_per_line,'Value',0)
      %       set(handles.radiobutton_f1_1mea_per_line,'Value',1)
      set(handles.edit_label_mea,'Enable', 'on')
      set(handles.edit_label_mea,'String', mlabel)
      set(handles.checkbox_include_used_latencies, 'Enable', 'on');
      set(handles.checkbox_include_used_latencies, 'Value', inclate);
end

%
% Measurements
%
set(handles.popupmenu_measurement,'value', indxmea);
set(handles.popupmenu_fracreplacement,'value', fracmenuindex);

%
%  NEW MENU (indxmea)
%

% 1 = 'Instantaneous amplitude',
% 2 = 'Mean amplitude between two fixed latencies',...
% 3 = 'Peak amplitude'
% 4 = 'Peak latency'
% 5 = 'Fractional Peak latency',...
% 6 = 'Numerical integration/Area between two fixed latencies'
% 7 = 'Numerical integration/Area between two (automatically detected) zero-crossing latencies'...
% 8 = 'Fractional Area latency'

set(handles.popupmenu_samp_amp,'value',sampeak+1);

switch indxmea
      case 1 % 'Instantaneous amplitude'
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.popupmenu_areatype,'Enable','off')
            set(handles.uipanel_inputlat, 'Title','at latency (just one)');
      case {2,6} % mean, area, integral between fixed latencies
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            if indxmea==6
                  set(handles.popupmenu_areatype,'Enable','on')
                  set(handles.popupmenu_areatype,'Value',areatype)
            else
                  set(handles.popupmenu_areatype,'Enable','off')
            end
      case {3,4} % 'Peak amplitude', 'Peak latency'
            menupeakon(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.popupmenu_pol_amp,'value',2-polpeak)
            %set(handles.popupmenu_samp_amp,'value',sampeak+1);
            set(handles.popupmenu_locpeakreplacement,'value',2-locpeakrep);
            set(handles.popupmenu_areatype,'Enable','off')
      case 5 % 'Fractional Peak latency'
            menupeakon(hObject, eventdata, handles)
            menufareaon(hObject, eventdata, handles)
            fracpos = round(frac*100)+1;
            set(handles.popupmenu_fraca,'Value', fracpos)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.text_fraca,'String', 'Fractional Peak')
            set(handles.popupmenu_pol_amp,'value',2-polpeak)
            %set(handles.popupmenu_samp_amp,'value',sampeak+1);
            set(handles.popupmenu_locpeakreplacement,'value',2-locpeakrep);            
            %set(handles.popupmenu_fracreplacement,'value',2-fracmearep);
            set(handles.popupmenu_areatype,'Enable','off')
      case 7 % area and integral with auto limits
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','seed latency (just one)');
            set(handles.popupmenu_areatype,'Enable','on')
            set(handles.popupmenu_areatype,'Value',areatype)
            
      case 8 % fractional area
            menupeakoff(hObject, eventdata, handles)
            menufareaon(hObject, eventdata, handles)
            fracpos = round(frac*100)+1;
            set(handles.popupmenu_fraca,'Value', fracpos)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
            set(handles.text_fraca,'String', 'Fractional Area')
            set(handles.popupmenu_areatype,'Enable','on')
            set(handles.popupmenu_areatype,'Value',areatype)
            set(handles.popupmenu_fracreplacement, 'String', {'"not a number" (NaN)', 'show error message'});
            
      otherwise
            menupeakoff(hObject, eventdata, handles)
            menufareaoff(hObject, eventdata, handles)
            set(handles.uipanel_inputlat, 'Title','between latencies (2)');
end

set(handles.edit_latency, 'String',  vect2colon(latency, 'Delimiter', 'off'))
set(handles.popupmenu_precision, 'Value', dig)

%
% Clear blc buttons
%
set(handles.popupmenu_baseliner, 'Value', indxblc)
if indxblc==5
      set(handles.edit_custombr,'Enable','on')
      try
            blcstrm = num2str(blc);
      catch
            blcstrm = '?????';
      end
      set(handles.edit_custombr,'String', blcstrm)
else
      set(handles.edit_custombr,'Enable','off')
end

set(handles.edit_bins, 'String', vect2colon(binArray, 'Delimiter', 'off'))
maxbi = max(binArray);
set(handles.popupmenu_bins,'Value', maxbi)

if binlabop==0
      set(handles.checkbox_binlabel, 'Value', 0) % use bin number as binlabel
else
      set(handles.checkbox_binlabel, 'Value', 1) % use bin descr as binlabel
end

set(handles.edit_channels, 'String', vect2colon(chanArray, 'Delimiter', 'off'))
maxch = max(chanArray);
set(handles.popupmenu_channels,'Value', maxch)
set(handles.edit_fname, 'String', fname);
set(handles.checkbox_send2ws, 'Value', send2ws);

if nsets>0 && optioni==0
      set(handles.radiobutton_erpset, 'Value', 1);
      set(handles.radiobutton_erpset, 'Enable', 'on');
      set(handles.radiobutton_folders, 'Value', 0);
      set(handles.listbox_erpnames, 'Enable', 'off');
      set(handles.button_adderpset, 'Enable', 'off');
      set(handles.button_delerpset, 'Enable', 'off');
      set(handles.button_savelistas, 'Enable', 'off');
      set(handles.button_savelist, 'Enable', 'off');
      set(handles.button_clearfile, 'Enable', 'off');
      set(handles.button_loadlist, 'Enable', 'off');
      set(handles.edit_erpset, 'String', vect2colon(erpset, 'Delimiter', 'off'));
      set(handles.listbox_erpnames, 'String', {'new erpset'});
      set(handles.edit_filelist,'String', '')
      set(handles.pushbutton_flush,'Enable','off')
      
      %
      % Prepare List of current Channels and bins
      %
      preparelists(ALLERP(erpset(1)), hObject, eventdata, handles);
      
else
      set(handles.radiobutton_folders, 'Value', 1);
      set(handles.radiobutton_erpset, 'Value', 0);
      set(handles.edit_erpset, 'Enable', 'off');
      set(handles.pushbutton_flush,'Enable','on')
      
      if nsets==0
            set(handles.radiobutton_erpset, 'Enable', 'off');
            set(handles.edit_erpset, 'String', 'no erpset');
      else
            set(handles.edit_erpset, 'String', vect2colon(1:nsets, 'Delimiter', 'off'));
      end
      
      %{option erpset fname latency binArray chanArray op coi dig blc binlabop polpeak sampeak localp}
      
      if ~isempty(erpset) && ischar(erpset)
            
            fid_list   = fopen( erpset );
            formcell = textscan(fid_list, '%[^\n]','CommentStyle','#', 'whitespace', '');
            lista = formcell{:};
            
            % extra line forward
            lista   = cat(1, lista, {'new erpset'});
            lentext = length(lista);
            fclose(fid_list);
            
            if lentext>1
                  try
                        ERP1 = load(strtrim(lista{1}), '-mat');
                        ERP = ERP1.ERP;
                        
                        if ~iserpstruct(ERP)
                              error('')
                        end
                        
                        handles.srate = ERP.srate;
                        %
                        % Prepare List of current Channels and bins
                        %
                        preparelists(ERP, hObject, eventdata, handles);
                        
                        set(handles.listbox_erpnames,'String',lista);
                        listname = erpset;
                        handles.listname = listname;
                        set(handles.button_savelistas, 'Enable','on')
                        set(handles.edit_filelist,'String', erpset)
                        
                        % Update handles structure
                        guidata(hObject, handles);
                  catch
                        handles.listname = [];
                        set(handles.button_savelist, 'Enable','off')
                        
                        % Update handles structure
                        guidata(hObject, handles);
                  end
            else
                  handles.listname = [];
                  set(handles.button_savelist, 'Enable','off')
                  
                  % Update handles structure
                  guidata(hObject, handles);
            end
      else
            set(handles.listbox_erpnames, 'String', {'new erpset'});
            set(handles.edit_filelist,'String', '')
      end
end

srate = handles.srate;

try
      msecstr = sprintf('pnts (%4.1f ms)', (sampeak/srate)*1000);
catch
      msecstr = 'pnts (... ms)';
end

set(handles.text_samp,'String',msecstr)

%
% Name & version
%
meamenu  = get(handles.popupmenu_measurement, 'String');
currentm = get(handles.popupmenu_measurement, 'Value');
version  = geterplabversion;
set(handles.figure1,'Name', ['ERPLAB ' version '   -   ERP Measurements GUI   -   ' meamenu{currentm}])

%--------------------------------------------------------------------------
function figure1_CreateFcn(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function checkbox_send2ws_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function pushbutton_flush_Callback(hObject, eventdata, handles)
set(handles.listbox_erpnames, 'String', {'new erpset'});
button_clearfile_Callback(hObject, eventdata, handles)
return

%--------------------------------------------------------------------------
% --- Executes on button press in radiobutton_f0_1erp_per_line.
function radiobutton_f0_1erp_per_line_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_f1_1mea_per_line,'Value',0)
      set(handles.edit_label_mea,'Enable', 'off')
else
      set(hObject,'Value',1)
end

%--------------------------------------------------------------------------
% --- Executes on button press in radiobutton_f1_1mea_per_line.
function radiobutton_f1_1mea_per_line_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      set(handles.radiobutton_f0_1erp_per_line,'Value',0)
      set(handles.edit_label_mea,'Enable', 'on')
else
      set(hObject,'Value',1)
end

%--------------------------------------------------------------------------
function edit_label_mea_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_label_mea_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit10_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit10_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_fraca_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_fraca_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function edit_custombr_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function edit_custombr_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_baseliner_Callback(hObject, eventdata, handles)

indxblc = get(handles.popupmenu_baseliner, 'Value');

if indxblc==5
      set(handles.edit_custombr,'Enable','on')
else
      set(handles.edit_custombr,'Enable','off')
end

%--------------------------------------------------------------------------
function popupmenu_baseliner_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_formatout_Callback(hObject, eventdata, handles)

if get(hObject,'Value')==2
      set(handles.edit_label_mea,'Enable','on')
      set(handles.checkbox_include_used_latencies,'Enable','on')
      mtype    = get(handles.popupmenu_measurement,'Value');
      areatype = get(handles.popupmenu_areatype,'Value');
      meatxt   = get(handles.edit_label_mea,'String');
      
      %
      % Suggestion for measurement labels
      %
      %       if isempty(meatxt)
      %             switch mtype
      %                   case 1
      %                         meatxt = 'insta_amp';
      %                   case 2
      %                         meatxt = 'mean_amp';
      %                   case 3
      %                         meatxt = 'peak_amp';
      %                   case 4
      %                         meatxt = 'peak_lat';
      %                   case 5
      %                         meatxt = 'frac_peak_lat';
      %                   case 6
      %                         if areatype==1
      %                               meatxt = 'area_2L';
      %                         elseif areatype==2
      %                               meatxt = 'integra_2L';
      %                         elseif areatype==3
      %                               meatxt = 'pos_area_2L';
      %                         elseif areatype==4
      %                               meatxt = 'neg_area_2L';
      %                         end
      %                   case 7
      %                         if areatype==1
      %                               meatxt = 'area_auto';
      %                         elseif areatype==2
      %                               meatxt = 'integra_auto';
      %                         elseif areatype==3
      %                               meatxt = 'pos_area_auto';
      %                         elseif areatype==4
      %                               meatxt = 'neg_area_auto';
      %                         end
      %                   case 8
      %                         meatxt = 'frac_area_lat';
      %             end
      %             set(handles.edit_label_mea,'String', meatxt );
      %       end
else
      set(handles.edit_label_mea,'Enable','off')
      set(handles.checkbox_include_used_latencies,'Enable','off')
end

%--------------------------------------------------------------------------
function popupmenu_formatout_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_fracreplacement_Callback(hObject, eventdata, handles)

% if get(hObject,'Value')==1
%       set(handles. popupmenu_fracreplacement,'Value',2)
% end

%--------------------------------------------------------------------------
function popupmenu_fracreplacement_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function popupmenu_areatype_Callback(hObject, eventdata, handles)

%--------------------------------------------------------------------------
function popupmenu_areatype_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
      set(hObject,'BackgroundColor','white');
end

%--------------------------------------------------------------------------
function checkbox_include_used_latencies_Callback(hObject, eventdata, handles)
