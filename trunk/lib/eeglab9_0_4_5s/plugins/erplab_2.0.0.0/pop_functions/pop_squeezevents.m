% 
% pop_squeezevents
% 
% PURPOSE  :	Summarizes current EEG event codes 
% 
% FORMAT   :
% 
% >> pop_squeezevents(EEG)
% 
% EXAMPLE  :
% 
% >> pop_squeezevents(EEG)
% 
% INPUTS   :
% 
% EEG				- EEG structure
% 
% OUTPUTS
% 
% -Summary of EEG event codes in command window
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

function [EEG com] = pop_squeezevents(EEG)

com = '';

if isempty(EEG(1))
      msgboxText{1} =  'pop_squeezevents() cannot work with an empty dataset.';
      title = 'ERPLAB: pop_squeezevents Permission denied';
      errorfound(msgboxText, title);
      return
end
if ~isempty(EEG(1).epoch)
      msgboxText{1} =  'pop_squeezevents() has been tested for continuous data only.';
      title = 'ERPLAB: pop_squeezevents Permission denied';
      errorfound(msgboxText, title);
      return
end
if isempty(EEG(1).data)
      msgboxText{1} =  'pop_squeezevents() cannot work with an empty dataset.';
      title = 'ERPLAB: pop_squeezevents Permission denied';
      errorfound(msgboxText, title);
      return
end
if isempty(EEG(1).event)
      msgboxText{1} =  'pop_squeezevents() cannot work with an empty dataset.';
      title = 'ERPLAB: pop_squeezevents Permission denied';
      errorfound(msgboxText, title);
      return
end
if isempty([EEG(1).event.type])
      msgboxText{1} =  'pop_squeezevents() cannot work with an empty dataset.';
      title = 'ERPLAB: pop_squeezevents Permission denied';
      errorfound(msgboxText, title);
      return
end

%
% process multiple datasets April 13, 2011 JLC
%
if length(EEG) > 1
   [EEG com ] = eeg_eval( 'pop_squeezevents', EEG, 'warning', 'on');
   return;
end

squeezevents(EEG.event);

com = sprintf( 'pop_squeezevents(%s);', inputname(1));
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end 
return