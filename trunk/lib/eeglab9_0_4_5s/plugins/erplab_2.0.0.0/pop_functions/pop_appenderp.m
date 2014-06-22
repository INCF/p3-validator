%
% Author: Javier Lopez-Calderon
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

function [ERP erpcom] = pop_appenderp(ALLERP,indx, prefixes)

erpcom = '';

ERP = preloadERP;
ERPaux = ERP;

if nargin<1
      help pop_appenderp
      return
end

if isempty(ALLERP)
      msgboxText =  'pop_appenderp() error: cannot work with an empty erpset!';
      title = 'ERPLAB: No data';
      errorfound(msgboxText, title);
      return
end

nloadedset = length(ALLERP);

if nargin==1
      
      answer = appenderpGUI(nloadedset);
      
      if isempty(answer)
            disp('User selected Cancel')
            return
      end
      
      indx      = answer{1};
      prefixes  = answer{2};
else      
      if nargin<3
            prefixes = [];
      end
      if nargin<2
            indx = 1:length(ALLERP);
      end
end

nerp    = length(indx);
nprefix = length(prefixes);

if ~isempty(prefixes)
      if nerp~=nprefix
            msgboxText{1} =  'Error: prefixes must to be as large as indx';
            title = 'ERPLAB: pop_appenderp() error:';
            errorfound(msgboxText, title);
            ERP = ERPaux;
            return
      end
end

[ERP serror] = appenderp(ALLERP,indx, prefixes);

if serror==0
      if nargin==1
            [ERP issave erpcom_save] = pop_savemyerp(ERP,'gui','erplab');
            
            if issave>0
                  erpcom = sprintf('ERP = pop_appenderp( %s, %s, { ', inputname(1), vect2colon(indx));
                  
                  for j=1:length(prefixes)
                        erpcom = sprintf('%s ''%s''  ', erpcom, prefixes{j} );
                  end;
                  
                  erpcom = sprintf('%s });', erpcom);
                  if issave==2
                        erpcom = sprintf('%s\n%s', erpcom, erpcom_save);
                        msgwrng = '*** Your ERPset was saved on your hard drive.***';
                  else
                        msgwrng = '*** Warning: Your ERPset was only saved on the workspace.***';
                  end
                  fprintf('\n%s\n\n', msgwrng)
            else
                  msgwrng = 'ERPLAB Warning: Your changes were not saved';
                  try cprintf([1 0.52 0.2], '%s\n\n', msgwrng);catch,fprintf('%s\n\n', msgwrng);end ;
                  ERP = ERPaux;
                  return
            end
      end
elseif serror==1
      msgboxText =  'Your ERPs do not have the same amount of channels!';
      title = 'ERPLAB: pop_appenderp() error:';
      errorfound(msgboxText, title);
      ERP = ERPaux;
      return
elseif serror==2
      msgboxText =  'Your ERPs do not have the same amount of points!';
      title = 'ERPLAB: pop_appenderp() error:';
      errorfound(msgboxText, title);
      ERP = ERPaux;
      return
else
      msgboxText =  'Error: Your ERPs are not compatibles!';
      title = 'ERPLAB: pop_appenderp() error:';
      errorfound(msgboxText, title);
      ERP = ERPaux;
      return
end

try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end
return
