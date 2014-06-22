% pop_eegremovemean (under construction...)
%
% PURPOSE  :	Remove DC offset from a continuous EEG dataset.
% 
% FORMAT   :
% 
% >> EEG = pop_eegremovemean( EEG, interval );
% 
% EXAMPLE  :
% 
% >>EEG = pop_eegremovemean( EEG, 1:40);
%
% 
% INPUTS   :
% 
% EEG          	- epoched EEG dataset
% chanArray	- channel indices to remove DC offset
%
% 
% OUTPUTS
% 
% EEG           - (updated) output dataset
%
%
% GUI: blcerpGUI.m ; SUBROUTINE: lindetrend.m
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

function [EEG, com] = pop_eegremovemean( EEG, chanArray)

com = '';

if nargin < 1
      help pop_eegremovemean
      return
end
if isempty(EEG(1).data)
      msgboxText =  'pop_eegremovemean() cannot read an empty dataset!';
      title = 'ERPLAB: pop_lindetrend error';
      errorfound(msgboxText, title);
      return
end
if ~isempty(EEG(1).epoch)
      msgboxText =  ['pop_eegremovemean works for continuous data only\n'...
                     'For epoched data you may use a baseline correction.\n'];
      title = 'ERPLAB: pop_lindetrend error';
      errorfound(msgboxText, title);
      return
end

%
% Gui is working...
%
if nargin <2      
      titlegui = 'Linear Detrend';
      answer = blcerpGUI(EEG(1), titlegui );  % open GUI      
      if isempty(answer)
            disp('User selected Cancel')
            return
      end      
      chanArray = answer{1};
end

%
% process multiple datasets April 13, 2011 JLC
%
if length(EEG) > 1
   [ EEG com ] = eeg_eval( 'pop_eegremovemean', EEG, 'warning', 'on', 'params', {chanArray});
   return;
end

EEG = lindetrend( EEG, interval);
EEG.setname = [EEG.setname '_ld']; % suggested name (si queris no mas!)

com = sprintf( '%s = pop_eegremovemean( %s, ''%s'' );', inputname(1), inputname(1), interval);
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return


