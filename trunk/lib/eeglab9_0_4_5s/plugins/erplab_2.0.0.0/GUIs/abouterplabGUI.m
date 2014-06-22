%
% Author: Javier Lopez-Calderon
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

function varargout = abouterplabGUI(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @abouterplabGUI_OpeningFcn, ...
        'gui_OutputFcn',  @abouterplabGUI_OutputFcn, ...
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

% -----------------------------------------------------------------------
function abouterplabGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output   = [];
handles.running  = 1;
handles.numfig   = 1;

[version reldate] = geterplabversion;
howold = num2str(datenum(date)-datenum(reldate));
set(handles.figure1,'Name', ['ABOUT  ERPLAB ' version ' (' howold ' days old)'])

p = which('eegplugin_erplab');
p = p(1:findstr(p,'eegplugin_erplab.m')-1);

fid_about = fopen( fullfile(p, 'GUIs', 'aboutext.txt'));
formcell  = textscan(fid_about, '%s','delimiter', '#');
firstline = {['ERPLAB version ' version]};
handles.textabout = cat(1,firstline, formcell{:});
fclose(fid_about);
handles.fontcred = 10;
try
      posgui  = erpworkingmemory('abouterplabGUI');
      xfig = posgui(1);
      yfig = posgui(2);
      disp('con memoria')
catch
      valscr = get(0,'MonitorPosition');
      %       posgui  = plotset.ptime.posgui;
      %       set(handles.figure1,'Position', posgui)       
      xfig     = min(valscr(:,3))/2;  % half width screen pos
      yfig     = 300;  % half width screen pos
      disp('sin memoria')
end

% Update handles structure
guidata(hObject, handles);
set(handles.figure1,'DoubleBuffer','on')
playcredit(handles.numfig, xfig, yfig, hObject, eventdata, handles)

% -----------------------------------------------------------------------
function varargout = abouterplabGUI_OutputFcn(hObject, eventdata, handles)
varargout{1} = [];

% -----------------------------------------------------------------------
function playcredit(numfig, xfig, yfig, hObject, eventdata, handles)

textabout = handles.textabout;
fontcred  = handles.fontcred;
[banner fcolor1 fcolor2 info ] = loadtheme(numfig, hObject, eventdata, handles);
%set(handles.figure1, 'Position', [xfig-(0.6*info.Width) 100 1.2*info.Width 1.1*info.Height])
set(handles.figure1, 'Position', [xfig yfig 1.2*info.Width 1.1*info.Height])
set(handles.axes1, 'Visible', 'off', 'Units', 'pixels', 'Position', [0 50 1.2*info.Width info.Height])
set(handles.text_cover,'Position', [0 0 1.2*info.Width 0.007*info.Height]);
wb = 110;
hb = 40.92;
yb = 6.38;
wfig = get(handles.figure1, 'Position');
x1 = wfig(3)*0.25-wb/2;
x2 = wfig(3)*0.5-wb/2;
x3 = wfig(3)*0.75-wb/2;
set(handles.pushbutton_erpinfo,'Units', 'pixels');
set(handles.pushbutton_relaunch,'Units', 'pixels');
set(handles.pushbutton_close,'Units', 'pixels');
set(handles.pushbutton_erpinfo,'Position', [x1 yb wb hb]);
set(handles.pushbutton_relaunch,'Position', [x2 yb wb hb]);
set(handles.pushbutton_close,'Position', [x3 yb wb hb]);

axes(handles.axes1)
holgu  = 0.12*info.Width;
dimmer = 0.98*sin(0:pi/160:0.8*pi); %[0:9 9 9 9 9:-1:4];
banner = loadtheme(numfig, hObject, eventdata, handles);
i=1;
while i<=length(dimmer) && get(handles.pushbutton_close,'Value')==0 && get(handles.pushbutton_relaunch,'Value')==0
        image(banner);
        set(handles.axes1, 'Visible', 'off', 'Units', 'pixels', 'Xlim',[-holgu info.Width+holgu]);
        alpha(dimmer(i))
        drawnow
        i=i+1;
        %pause(0.15)
end

namefont = 'Arial';
mleft    = -holgu*0.65;
kbottom  = 2.1;
i = 0;
banner = loadtheme(numfig, hObject, eventdata, handles);
while i<=2.72*info.Height && get(handles.pushbutton_close,'Value')==0 && get(handles.pushbutton_relaunch,'Value')==0
      text(mleft, kbottom*info.Height-i, textabout,'FontName', namefont, 'Fontsize', fontcred,'Color', fcolor1)
      drawnow
      image(banner);
      set(handles.axes1, 'Visible', 'off', 'Units', 'pixels', 'Xlim',[-holgu info.Width+holgu]);
      alpha(dimmer(end))
      i = i + 1;
end
if get(handles.pushbutton_relaunch,'Value')==1
      set(handles.pushbutton_relaunch,'Value', 0)
      numfig  = round(rand*9) + 1;
      while numfig==handles.numfig
            numfig  = round(rand*9) + 1;
      end
      handles.numfig = numfig;
      % Update handles structure
      guidata(hObject, handles);
      
      posgui = get(handles.figure1,'Position');
      xfig = posgui(1);
      yfig = posgui(2);
      playcredit(numfig, xfig, yfig, hObject, eventdata, handles)
      return
end
i=length(dimmer);
while i>length(dimmer)/2 && get(handles.pushbutton_close,'Value')==0 && get(handles.pushbutton_relaunch,'Value')==0
      image(banner);
      set(handles.axes1, 'Visible', 'off', 'Units', 'pixels', 'Xlim',[-holgu info.Width+holgu]);
      alpha(dimmer(i))
      drawnow
        i=i-1;
        %pause(0.15)
end

handles.running  = 0;
% Update handles structure
guidata(hObject, handles);

if get(handles.pushbutton_close,'Value')==1
        delete(handles.figure1)
end
return

% -----------------------------------------------------------------------
function pushbutton_close_Callback(hObject, eventdata, handles)
posgui = get(handles.figure1,'Position');
erpworkingmemory('abouterplabGUI', posgui);
if handles.running  == 0;
      delete(handles.figure1)
end

% -----------------------------------------------------------------------
function pushbutton_relaunch_Callback(hObject, eventdata, handles)
posgui = get(handles.figure1,'Position');
xfig = posgui(1);
yfig = posgui(2);

if handles.running==0
      %abouterplabGUI
      playcredit(1, xfig, yfig, hObject, eventdata, handles)
end

% -----------------------------------------------------------------------
function pushbutton_erpinfo_Callback(hObject, eventdata, handles)
posgui = get(handles.figure1,'Position');
erpworkingmemory('abouterplabGUI', posgui);

set(handles.pushbutton_close,'Value', 1)
if handles.running  == 0;
      delete(handles.figure1)
end
pause(0.2)
web('http://www.erpinfo.org/erplab/','-browser')

% -----------------------------------------------------------------------
function [banner fcolor1 fcolor2 info ] = loadtheme(numfig, hObject, eventdata, handles)

if numfig==8 || numfig==1
        set(handles.figure1,'Color',[0 0 0]);
        set(handles.text_cover,'BackgroundColor',[0 0 0]);
        fcolor1 = [1 1 1];
        fcolor2 = [0 0 0];
else
        set(handles.figure1,'Color',[1 1 1]);
        set(handles.text_cover,'BackgroundColor',[1 1 1]);
        fcolor1 = [0 0 0];
        fcolor2 = [1 1 1];
end

%if numfig==9
%        namefig = 'logoerplab2010ny.jpg';
%else
        namefig = ['logoerplab' num2str(numfig) '.jpg'];
%end

set(hObject, 'Units', 'pixels');
set(handles.axes1, 'Units', 'pixels');
banner  = double(imread(namefig));       % Read the image file banner.jpg
info    = imfinfo(namefig);      % Determine the size of the image file
edition  = double(imread('Steve_Jobs_signature.tif'));       % Read the image file banner.jpg
edmask = edition;
edmask(edmask~=55) = 0;
edmask(edmask==55) = 255;
edmask = edmask/255;
edsum = edition;
edsum(edsum==55) = 0;
banner = banner .* edmask;
banner = banner + edsum*0.9;
banner = uint8(round(banner));

%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)

posgui = get(handles.figure1,'Position');
erpworkingmemory('abouterplabGUI', posgui);
if get(handles.pushbutton_close,'Value')==1 % in case of problems...
      delete(handles.figure1)
end

% or

set(handles.pushbutton_close,'Value', 1) % normal closing
if handles.running  == 0;
      delete(handles.figure1)
end
