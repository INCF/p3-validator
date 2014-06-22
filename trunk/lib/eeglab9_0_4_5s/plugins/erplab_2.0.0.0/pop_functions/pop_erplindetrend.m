% pop_erplindetrend
%
% PURPOSE  :	Remove linear trends from each bin of an ERPset.
% 
% FORMAT   :
% 
% >> ERP = pop_erplindetrend( ERP, interval );
% 
% EXAMPLE  :
% 
% >>ERP = pop_erplindetrend( ERP, 'pre');
% >>ERP = pop_erplindetrend( ERP, [-300 100]);
% 
% INPUTS   :
% 
% ERP          	- input ERPset
% Interval	- time window to estimate the trend. This trend will be subtracted from the whole epoch.
%
% 
% OUTPUTS
% 
% ERP           - (updated) output ERPset
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

function [ERP erpcom] = pop_erplindetrend( ERP, interval)

erpcom = '';

if nargin < 1
      help pop_lindetrend
      return
end
if isempty(ERP)
      msgboxText =  'pop_lindetrend() cannot read an empty ERPset!';
      title = 'ERPLAB: pop_lindetrend() error';
      errorfound(msgboxText, title);
      return
end

%
% Gui is working...
%
if nargin <2
      
      titlegui = 'Linear Detrend';
      answer = blcerpGUI(ERP, titlegui );  % open GUI
      
      if isempty(answer)
            disp('User selected Cancel')
            return
      end
      
      interval = answer{1};
end
if ischar(interval)
      if ~strcmpi(interval,'all') && ~strcmpi(interval,'pre') && ~strcmpi(interval,'post')
            
            internum = str2num(interval);
            
            if length(internum)~=2
                  msgboxText = 'Wrong interval. Linear detrending will not be performed.';
                  title = 'ERPLAB: pop_erplindetrend() error';
                  errorfound(msgboxText, title);
                  return
            end
            intervalstr = ['[ ' num2str(internum) ' ]'];
      else
            intervalstr = ['''' interval ''''];
      end
else
      if length(interval)~=2
            msgboxText = 'Wrong interval. Linear detrending will not be performed.';
            title = 'ERPLAB: pop_erplindetrend() error';
            errorfound(msgboxText, title);
            return
      end
      intervalstr = ['[ ' num2str(interval) ' ]'];
end

ERPaux = ERP;
ERP = lindetrend( ERP, interval);
ERP.erpname = [ERP.erpname '_ld']; % suggested name (si queris no mas!)
ERP.saved   = 'no';

if nargin==1
      
      [ERP issave erpcom_save] = pop_savemyerp(ERP,'gui','erplab');
      
      if issave>0
            % generate text command
            erpcom = sprintf( '%s = pop_erplindetrend( %s, %s );', inputname(1), inputname(1), intervalstr);
            if issave==2
                  erpcom = sprintf('%s\n%s', erpcom, erpcom_save);
                  msgwrng = '*** Your ERPset was saved on your hard drive.***';
            else
                  msgwrng = '*** Warning: Your ERPset was only saved on the workspace.***';
            end
            fprintf('\n%s\n\n', msgwrng)
            try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
            return
      else
            ERP = ERPaux;
            msgwrng = 'ERPLAB Warning: Your changes were not saved';
            try cprintf([1 0.52 0.2], '%s\n\n', msgwrng);catch,fprintf('%s\n\n', msgwrng);end ;
            return
      end
end

