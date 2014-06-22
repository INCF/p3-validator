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

function [ERP erpcom] = pop_clearerpchanloc(ERP)

erpcom = '';

if isempty(ERP)
      msgboxText{1} =  'cannot operate an empty ERP dataset';
      title = 'ERPLAB: pop_clearerpchanloc() error:';
      errorfound(msgboxText, title);
      return
end
if ~iserpstruct(ERP)
      msgboxText{1} =  'Invalid ERP structure';
      title = 'ERPLAB: pop_clearerpchanloc() error:';
      errorfound(msgboxText, title);
      return
end

%
% Store original chan info
%
chanlocsaux = ERP.chanlocs;

if isfield(ERP.chanlocs,'labels')
      labels = {ERP.chanlocs.labels};
      ERP.chanlocs = [];
      [ERP.chanlocs(1:length(labels)).labels] = labels{:};
end

[ERP issave erpcom_save] = pop_savemyerp(ERP,'gui','erplab');

if issave>0
      erpcom = sprintf('%s = pop_clearerpchanloc(%s);', inputname(1), inputname(1));
      if issave==2
            erpcom = sprintf('%s\n%s', erpcom, erpcom_save);
            msgwrng = '*** Your ERPset was saved on your hard drive.***';
      else
            msgwrng = '*** Warning: Your ERPset was only saved on the workspace.***';
      end
      fprintf('\n%s\n\n', msgwrng)
else
      ERP.chanlocs = chanlocsaux;
end
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return