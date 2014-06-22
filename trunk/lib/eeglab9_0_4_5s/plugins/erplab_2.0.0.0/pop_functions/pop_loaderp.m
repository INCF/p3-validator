% pop_loadmerplabset
% 
% PURPOSE  :	Loads multiple EEG datasets on the EEGLAB GUI (deprecated)
% 
% FORMAT   :
% 
% >> [ALLEEG EEG CURRENTSET] = pop_loadmerplabset(ALLEEG, EEG)
% 
% EXAMPLE  :
% 
% >> [ALLEEG EEG CURRENTSET] = pop_loadmerplabset(ALLEEG, EEG)  -gui 
% will apear
% 
% INPUTS   :
% 
% ALLEEG 			- ALLEEG structure (containing EEG structures) 
% EEG				- EEG structure
% 
% OUTPUTS  :
% 
% ERP 				- output ERPset
%
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright © 2007 The Regents of the University of California
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

function [ERP ALLERP erpcom] = pop_loaderp(filename, pathname)

erpcom = '';
ERP = preloadERP;


try
      ALLERP   = evalin('base', 'ALLERP');
      preindex = length(ALLERP);
catch
      disp('WARNING: ALLERP structure was not found.')
      ALLERP = [];
      %ALLERP   = builtERPstruct([]);
      preindex = 0;
end

% try
%       ALLERP   = evalin('base', 'ALLERP');
%       if ~isempty(ALLERP)
%             if isstruct(ALLERP)
%                   if ~iserpstruct(ALLERP(1))
%                         disp('WARNING: ALLERP structure was resetted.')
%                         %ALLERP = [];
%                         ALLERP   = builtERPstruct([]);
%                         preindex = 0;
%                   end
%             else
%                   disp('WARNING: ALLERP structure was resetted.')
%                   %ALLERP = [];
%                   ALLERP   = builtERPstruct([]);
%                   preindex = 0;
%             end
%       else
%           ALLERP   = builtERPstruct([]);
%                         preindex = 0;  
%       end
%       preindex = length(ALLERP);
% catch
%       disp('WARNING: ALLERP structure was not found.')
%       %ALLERP = [];
%       ALLERP   = builtERPstruct([]);
%       preindex = 0;
% end
% 
% ALLERP


if nargin<1
      help pop_loaderp
      return
end
if nargin>2
      error('ERPLAB says: error at pop_loaderp() too many inputs!')
end

option = 1; % load from hard drive
menup  = 0; % no popup window

if nargin==1
      if strcmpi(filename,'workspace')
            pathname = '';
            nfile = 1;
            option = 0;  % load from workspace
      else
            if isempty(filename)
                  [filename, pathname] = uigetfile({'*.erp','ERP (*.erp)';...
                        '*.mat','ERP (*.mat)'}, ...
                        'Load ERP', ...
                        'MultiSelect', 'on');
                  if isequal(filename,0)
                        disp('User selected Cancel')
                        return
                  end
                  menup = 1; % popup window
                  
                  %
                  % test current directory
                  %
                  changecd(pathname)
            else
                  pathname = cd;
                  %
                  %                   if iscell(filename)
                  %                   else
                  %
                  %
                  %
                  %
                  %                   [pathname, filenamex, ext, versn] = fileparts(filename);
                  %
                  %                   filename = [filenamex ext];
                  %                   if isempty(pathname)
                  %                         pathname = cd;
                  %                   end
            end
      end
end
if option==1
      if iscell(filename)
            nfile      = length(filename);
            inputfname = filename;
      else
            nfile = 1;
            inputfname = {filename};
      end
else
      inputfname = {'workspace'};
end

inputpath = pathname;
errorf = 0; % no error by default
conti  =1;

for i=1:nfile
      
      if option==1
            L   = load(fullfile(inputpath, inputfname{i}), '-mat');
            ERP = L.ERP;
      else
            ERP = evalin('base', 'ERP');
      end
      
      [ERP conti serror] = olderpscan(ERP, menup);
      
      if conti==0
            break
      end
      
      if serror
            msgboxText = ['Your erpset %s is not compatible at all with the current ERPLAB version.\n'...
                  'Please, try upgrading your ERP structure.'];
            title = 'ERPLAB: pop_loaderp() Error';
            errorfound(sprintf(msgboxText, ERP.filename), title);
            errorf = 1;
            break
      end
      
      checking = checkERP(ERP);
      
      %       try
      if checking
            if i==1 && isempty(ALLERP);
                  ALLERP = builtERPstruct([]);
                  ALLERP = ERP;
            else
                  ALLERP(i+preindex) = ERP;
            end
      else
            msgboxText = ['Your erpset %s contains errors or it is not compatible at all with the current ERPLAB version.\n'...
                  'Please, try upgrading your ERP structure.'];
            title = 'ERPLAB: pop_loaderp() Error';
            errorfound(sprintf(msgboxText, ERP.filename), title);
            errorf = 1;
            break
      end
      %       catch
      %             msgboxText = cell(1);
      %             msgboxText{1} =  sprintf('Your erpset %s is not compatible at all with the current ERPLAB version',ERP.filename);
      %             msgboxText{2} =  'Please, try upgrading your ERP structure.';
      %             title = 'ERPLAB: pop_loaderp() Error';
      %             errorfound(msgboxText, title);
      %             errorf = 1;
      %             break
      %       end
end
if conti==0
      return
end
if ~errorf && ~serror && nargin==1 && menup==1
      assignin('base','ALLERP',ALLERP);  % save to workspace
      updatemenuerp(ALLERP);      
      if option==1
            erpcom = sprintf('ERP = pop_loaderp({ ');
            for i=1:nfile
                  erpcom = sprintf('%s''%s'' ', erpcom, inputfname{i});
            end
            erpcom = sprintf('%s}, ''%s'');',erpcom, inputpath);
      else
            erpcom = sprintf('ERP = pop_loaderp(''%s'');', inputfname{1});
      end
else
      if strcmpi(filename,'workspace')
            assignin('base','ALLERP',ALLERP);  % save to workspace
      updatemenuerp(ALLERP);            
      end
end
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
%ALLERP
return