% pop_creabasiceventlist
%
% PURPOSE  :	Creates the EVENTLIST structure with the event information 
%               extracted and reorganized from EEG.event (default) or from 
%               an external list (text file). The EVENTLIST structure is 
%               attached to the EEG structure. 
% 
% FORMAT   :
% 
% >> EEG = pop_creabasiceventlist( EEG, elname );
% 
% EXAMPLE  :
% 
% >> EEG = pop_creabasiceventlist( EEG, 
% ?C:\Controls\Test\eventlist_S01.txt? );
% 
% INPUTS   :
% 
% EEG           - input dataset
% elname        - name of the text file will contain the event 
%               information according to ERPLAB format 
% 
% OUTPUTS
% 
% EEG 			- (updated) output dataset
%
%
% GUI: creabasiceventlistGUI.m ; SUBROUTINE: --
%
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

function [EEG com] = pop_creabasiceventlist(EEG, elname, boundarystrcode, newboundarynumcode, rwwarn)

com = '';

if nargin < 1
      help pop_creabasiceventlist
      return
end
if length(EEG)>1
      msgboxText =  'Unfortunately, this function does not work with multiple datasets';
      title = 'ERPLAB: multiple inputs';
      errorfound(msgboxText, title);
      return
end
if nargin >5
      error('ERPLAB says: error at pop_creabasiceventlist(). Too many inputs!');
end
if ~isempty(EEG.epoch)
      msgboxText =  ['pop_creabasiceventlist() has been tested for continuous data only.\n\n'...
                     'HINT: You could use "Export EVENTLIST to text file", instead.'];
      title = 'ERPLAB: pop_creabasiceventlist Permission denied';
      errorfound(sprintf(msgboxText), title);
      return
end

if isfield(EEG, 'EVENTLIST')
      if isfield(EEG.EVENTLIST, 'eventinfo')
            if ~isempty(EEG.EVENTLIST.eventinfo)
                  
                  if nargin==1
                        question   = ['dataset %s  already has attached an EVENTLIST structure.\n'...
                                      'So, pop_creabasiceventlist()  will totally overwrite it.\n'...
                                      'Do you want to continue anyway?'];
                        title      = 'ERPLAB: binoperator, Overwriting Confirmation';
                        button     = askquest(sprintf(question, EEG.setname), title);
                        
                        if ~strcmpi(button,'yes')
                              disp('User selected Cancel')
                              return
                        end
                  else
                        fprintf('\n\nWARNING: Previous EVENTLIST structure will be overwritten.\n\n')
                  end
                  
                  if ischar(EEG.event(1).type)
                        [ EEG.event.type ] = EEG.EVENTLIST.eventinfo.code;
                  end
                  
                  EEG.EVENTLIST = [];
                  
                  %field2del = {'bepoch','bini','binlabel','codelabel','enable','flag','item'};
                  %trufields = isfield(EEG.event, field2del);
                  %field2del = field2del(trufields);
                  %EEG.event = rmfield(EEG.event, field2del);
            end
      end
end
if nargin==1
      
      if isempty(EEG.data)
            msgboxText =  'pop_creabasiceventlist() error: cannot work with an empty dataset!';
            title = 'ERPLAB: No data';
            errorfound(msgboxText, title);
            return
      end
      
      inputstrMat = creabasiceventlistGUI;  % GUI
      
      if isempty(inputstrMat) && ~strcmp(inputstrMat,'')
            disp('User selected Cancel')
            return
      end
      
      elname    = inputstrMat{1};
      boundarystrcode    = inputstrMat{2};
      newboundarynumcode = inputstrMat{3};
      rwwarn = 1;
      
else
        if nargin <5
                rwwarn = 0;
        end
        if nargin <4
                newboundarynumcode = -99;
        end
        if nargin <3
                boundarystrcode = 'boundary';
        end
end

field2del = {'bepoch','bini','binlabel', 'code', 'codelabel','enable','flag','item'};
tf  = ismember(field2del,fieldnames(EEG.event)');

if rwwarn && nnz(tf)>0
      question = ['The EEG.event field of ' EEG.setname ' contains subfield name(s) reserved for ERPLAB.\\nn'...
            'What would you like to do?\n\n'];
      BackERPLABcolor = [1 0.9 0.3];    % yellow
      title      = 'ERPLAB: pop_creabasiceventlist, Overwriting Confirmation';
      oldcolor    = get(0,'DefaultUicontrolBackgroundColor');
      set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
      button      = questdlg(sprintf(question), title,'Cancel','Overwrite them', 'Continue as it is', 'Overwrite them');
      set(0,'DefaultUicontrolBackgroundColor',oldcolor)
      
      if strcmpi(button,'Continue as it is')
            fprintf('|WARNING: Fields found in EEG.event that has ERPLAB''s reserved names will not be overwritten.\n\n');
      elseif strcmpi(button,'Cancel') || strcmpi(button,'')
            return
      elseif strcmpi(button,'Overwrite them')
            %bepoch bini binlabel codelabel duration enable flag item latency type urevent
            EEG.event = rmfield(EEG.event, field2del(tf));
            fprintf('|WARNING: Fields found in EEG.event that has ERPLAB''s reserved names were overwritten.\n\n')
      end
end

% %
% % Delete white spaces from alphanumeric event codes (if any)
% %
% EEG = wspacekiller(EEG);

boundarystrcode = strtrim(boundarystrcode);
boundarystrcode = regexprep(boundarystrcode, '''|"','');

EEG = pop_editeventlist(EEG, '', elname, boundarystrcode, newboundarynumcode, rwwarn); % do it without warnings
EEG = pop_overwritevent(EEG, 'code');

if length(boundarystrcode)==1
      com = sprintf( '%s = pop_creabasiceventlist(%s, ''%s'', {''%s''}, {%s}, %s);', inputname(1),...
            inputname(1), elname, boundarystrcode{1}, num2str(newboundarynumcode{1}), num2str(rwwarn));
elseif length(boundarystrcode)==2
      com = sprintf( '%s = pop_creabasiceventlist(%s, ''%s'', {''%s'',''%s'' }, {%s, %s}, %s);', inputname(1),...
            inputname(1), elname, boundarystrcode{1}, boundarystrcode{2},...
            num2str(newboundarynumcode{1}), num2str(newboundarynumcode{2}), num2str(rwwarn));
else
      com = sprintf( '%s = pop_creabasiceventlist(%s, ''%s'');', inputname(1), inputname(1), elname);
end

try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return;
