% pop_binoperator
% 
% PURPOSE  :	Creates and modifies bins that are linear combinations of 
%               the bins in the current ERP structure
% 
% FORMAT   :
% 
% >> ERP = pop_binoperator(ERP, formulas, option);
% 
% EXAMPLE  :
% 
% >> ERP = pop_binoperator( ERP, {'b38 = b7-b8 label hot 5'}, 0);
% 
% 
% INPUTS   :
% 
% ERP           - input ERPset
% Formulas      - expression(s) for new bin(s) (cell string(s)).
% Option        - 0=append new bin(s). 1=mount new bin(s) into a new 
%                 ERP structure.
% 
% OUTPUTS  :
% 
% ERP           - (updated) output ERPset
%
%
% GUI: binoperGUI.m ; SUBROUTINE: binoperator.m
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

function [ERP erpcom] = pop_binoperator(ERP, formulas)

erpcom = '';

if nargin < 1
      help(sprintf('%s', mfilename))
      return
end
if nargin >2
      error('ERPLAB says:  Error, too many inputs')
end
if isempty(ERP)
      msgboxText{1} =  'pop_binoperator cannot operate an empty ERP dataset';
      title = sprintf('ERPLAB: %s() error:', mfilename);
      errorfound(msgboxText, title);
      return
end
if ~isfield(ERP, 'bindata')
      msgboxText{1} =  'pop_binoperator cannot operate an empty ERP dataset';
      title = sprintf('ERPLAB: %s() error:', mfilename);
      errorfound(msgboxText, title);
      return
end
if isempty(ERP.bindata)
      msgboxText{1} =  'pop_binoperator cannot operate an empty ERP dataset';
      title = sprintf('ERPLAB: %s() error:', mfilename);
      errorfound(msgboxText, title);
      return
end
if nargin==1
      answer = binoperGUI(ERP);   % call a GUI*
      if isempty(answer)
            disp('User selected Cancel')
            return
      end
      formulas = answer{1};
else
      %
      % no warnings about existing bins
      %
      erpworkingmemory('wbmsgon',0)
end
if iscell(formulas)
      formulaArray = formulas';
      opcom = 1; % ---> cell array with formulas
else
      if isnumeric(formulas)
            error('ERPLAB says:  Error, formulas must be a cell string or a filename')
      end
      if strcmp(formulas,'')
            error('ERPLAB says:  Error, formulas were not found.')
      end
      
      disp(['For list of formulas, user selected  <a href="matlab: open(''' formulas ''')">' formulas '</a>'])
      
      fid_formulas = fopen( formulas );
      formulaArray = textscan(fid_formulas, '%[^\n]', 'CommentStyle','#', 'whitespace', '');
      formulaArray = strtrim(cellstr(formulaArray{:})');
      fclose(fid_formulas);
      
      if isempty(formulaArray)
            error('ERPLAB says:  Error, file was empty. No formulas were found.')
      end
      
      opcom = 2; % ---> filename where formulas are described.
end

ERP_tempo = ERP;

%
% Check formulas
%
[option recall goeson] = checkformulas(formulaArray, mfilename);
nformulas  = length(formulaArray);

if recall  && nargin==1
      [ERP erpcom] = pop_binoperator(ERP); % try again...
      return
end
if option==1  % create new ERP struct
      ERPin = ERP;
      % New empty ERP
      ERPout= builtERPstruct([]);
else  % work over the current ERP struct
      ERPin = ERP;
      ERPout= ERPin;
end

h=1;

while h<=nformulas && goeson
      expr = formulaArray{h};
      tokcommentb  = regexpi(formulaArray{h}, '^#', 'match');  % comment
      if isempty(tokcommentb)
            [ERPout conti cancelop] = binoperator(ERPin, ERPout, expr);
            if cancelop && nargin==1
                  recall = 1;
                  break
            end
            if conti==1
                  if isempty(ERPout)
                        error(' ERPLAB says: something is wrong...')
                  end
                  if ~option  % work over the current ERP struct
                        test = checkchannel(ERPout, ERPin);
                        
                        if test==0
                              ERPin = ERPout; % recursive
                        else
                              if test==1
                                    bann = 'Number';
                              else
                                    bann = 'Label';
                              end
                              title = 'ERPLAB: Create a new ERP';
                              question = ['%s of channels are different for this bin!\n'...
                                    'You must save it as a new ERP.\n Please, use "nbin" sintax instead.\n\n'...
                                    ' Would you like to try again?'];
                              button = askquest(sprintf(question, bann), title);
                              if strcmpi(button,'yes')
                                    disp('User selected Cancel')
                                    recall = 1;
                                    break
                              else
                                    goeson = 0;
                              end
                        end
                  end
            end
      end
      h = h + 1;
end

if ~isfield(ERPout, 'binerror')
      ERPout.binerror = [];
end
if ~goeson
      ERP = ERP_tempo; % recover unmodified ERP
      disp('Warning: Your ERP structure has not yet been saved')
      disp('user canceled')
      return
end
if recall  && nargin==1
      ERP = ERP_tempo;
      [ERP erpcom] = pop_binoperator(ERP); % try again...
      return
end
if option==1 % create new ERP
      ERPout.workfiles = ERPin.workfiles;
      ERPout.xmin      = ERPin.xmin;
      ERPout.xmax      = ERPin.xmax;
      ERPout.times     = ERPin.times;
      ERPout.pnts      = ERPin.pnts;
      ERPout.srate     = ERPin.srate;
      ERPout.isfilt    = ERPin.isfilt;
      ERPout.ref       = ERPin.ref;
      ERPout.EVENTLIST = ERPin.EVENTLIST;
end

ERP = ERPout;

if nargin<2 && option==1  % only for GUI and nbins (new ERP)
      
      [ERP issave erpcom_save] = pop_savemyerp(ERP,'gui','erplab');
      if issave>0
            if opcom==1
                  erpcom = sprintf('%s = pop_binoperator( %s, { ', inputname(1), inputname(1));
                  for j=1:nformulas;
                        erpcom = sprintf('%s ''%s''  ', erpcom, formulaArray{j} );
                  end;
                  erpcom = sprintf('%s });', erpcom);
            else
                  erpcom = sprintf('%s = pop_binoperator( %s, ''%s'');', inputname(1), inputname(1),...
                        formulas);
            end
            if issave==2
                  erpcom = sprintf('%s\n%s', erpcom, erpcom_save);
                  msgwrng = '*** Your ERPset was saved on your hard drive.***';
            else
                  msgwrng = '*** Warning: Your ERPset was only saved on the workspace.***';
            end
            fprintf('\n%s\n\n', msgwrng)
      else
            ERP = ERP_tempo; % recover unmodified ERP
            msgwrng = 'ERPLAB Warning: Your changes were not saved';
            try cprintf([1 0.52 0.2], '%s\n\n', msgwrng);catch,fprintf('%s\n\n', msgwrng);end ;
            return
      end      
elseif nargin<2 && option==0  % overwrite current ERP (no GUI)      
      ERP = pop_savemyerp(ERP, 'gui', 'erplab', 'overwriteatmenu', 'yes');      
      if opcom==1
            erpcom = sprintf('%s = pop_binoperator( %s, { ', inputname(1), inputname(1));
            for j=1:nformulas;
                  erpcom = sprintf('%s ''%s''  ', erpcom, formulaArray{j} );
            end;
            erpcom = sprintf('%s });', erpcom);
      else
            erpcom = sprintf('%s = pop_binoperator( %s, ''%s'');', inputname(1), inputname(1),...
                  formulas);
      end      
end
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return

