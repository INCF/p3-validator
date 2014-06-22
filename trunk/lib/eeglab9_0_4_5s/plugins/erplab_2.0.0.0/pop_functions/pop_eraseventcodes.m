% pop_eraseventcodes
%
% PURPOSE  :	Erases numeric event codes according to a logical 
%               expression.
% 
% FORMAT   :
% 
% >> EEG = pop_eraseventcodes( EEG, expr )
% 
% EXAMPLE  :
% >> EEG = pop_eraseventcodes( EEG, �>255� ); % deletes all event codes 
% greater than 255
% 
% INPUTS   :
% 
% EEG 			- input dataset
% expr			- logical expression '�=value'�,'�>value'�,'�<value'�,'�~=value'�, 
%                         '�>=value'�,'�<=value'� 
% 
% OUTPUTS  :
% 
% EEG 			- updated output dataset
%
%
% GUI: inputvalue.m  ;  SUBROUTINE: eraseventcodes.m
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

function [EEG com] = pop_eraseventcodes( EEG, expr)

com = '';

if nargin < 1
      help pop_eraseventcodes
      return
end
if isempty(EEG(1).data)
      msgboxText =  'pop_eraseventcodes() cannot read an empty dataset!';
      title = 'ERPLAB: pop_eraseventcodes error';
      errorfound(msgboxText, title);
      return
end
if ~isempty(EEG(1).epoch)
      msgboxText =  'pop_eraseventcodes has been tested for continuous data only';
      title = 'ERPLAB: pop_eraseventcodes(). Permission denied';
      errorfound(msgboxText, title);
      return
end
if ~isfield(EEG(1), 'event')
      msgboxText =  'pop_eraseventcodes did not find EEG.event field.';
      title = 'ERPLAB: pop_eraseventcodes(). Permission denied';
      errorfound(msgboxText, title);
      return
end
if ~isfield(EEG(1).event, 'type')
      msgboxText =  'pop_eraseventcodes did not find EEG.event.type field.';
      title = 'ERPLAB: pop_eraseventcodes(). Permission denied';
      errorfound(msgboxText, title);
      return
end
if ~isfield(EEG(1).event, 'latency')
      msgboxText =  'pop_eraseventcodes did not find EEG.event.latency field.';
      title = 'ERPLAB: pop_eraseventcodes(). Permission denied';
      errorfound(msgboxText, title);
      return
end
if ischar(EEG(1).event(1).type)
      msgboxText =  ['pop_eraseventcodes only works with numeric event codes.\n'...
                     'We recommend to use Create EEG Eventlist - Basic first.'];
      title = 'ERPLAB: pop_eraseventcodes(). Permission denied';
      errorfound(sprintf(msgboxText), title);
      return
end

%
% Gui is working...
%
if nargin <2
      
      prompt    = {'expression (>, < ==, ~=):'};
      dlg_title = 'Input event-code condition to delete';
      num_lines = 1;
      
      def = {'>255'};
      answer = inputvalue(prompt,dlg_title,num_lines,def);
      
      if isempty(answer)
            disp('User selected Cancel')
            return
      end
      expression = answer{1};
else
      expression = expr;      
end

%
% process multiple datasets April 13, 2011 JLC
%
if length(EEG) > 1
   [ EEG com ] = eeg_eval( 'pop_eraseventcodes', EEG, 'warning', 'on', 'params', {expr});
   return;
end

EEG = eraseventcodes( EEG, expression);
EEG.setname = [EEG.setname '_2']; % suggested name (si queris no mas!)

com = sprintf( '%s = pop_eraseventcodes( %s, ''%s'' );', inputname(1), inputname(1), expression);
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return


