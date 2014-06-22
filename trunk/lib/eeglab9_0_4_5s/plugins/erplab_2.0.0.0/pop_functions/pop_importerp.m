% pop_importerp
%
% >> ERP = pop_importerp(filename, pathname, filetype, options)
%
% Options:
%  'time'       - 'on', 'off'
%  'timeunit'   - 1E-3  (milliseconds)
%  'elabel'     - 'on', 'off'
%  'pointat'    - 'column','row'
%  'srate'      - 1E3 (samples per second)
%  'xlim'       - [-200 800]
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
function [ERP erpcom]= pop_importerp(filename, pathname, filetype, varargin)

erpcom = '';
ERP = preloadERP;

if nargin<1
      
      def  = erpworkingmemory('pop_importerp');
      
      if isempty(def)
            def = {'','','',0,1,0,0,1000,[-200 800]};
      end
      %
      % Call GUI
      %
      getlista = importerpGUI(def);
      
      if isempty(getlista)
            disp('User selected Cancel')
            return
      end
      
      filename    = getlista{1};
      pathname    = getlista{2};
      ftype       = getlista{3};
      includetime = getlista{4};
      timeunit    = getlista{5};
      elabel      = getlista{6};
      transpose   = getlista{7};
      fs          = getlista{8};
      xlim        = getlista{9};
      
      typef = {'text', 'neuroscan'};
      
      filetype = typef(ftype);
      
      erpworkingmemory('pop_importerp', {filename, pathname, ftype,includetime,timeunit,elabel,transpose,fs,xlim});     
else
      p = inputParser;
      p.FunctionName  = mfilename;
      p.CaseSensitive = false;
      %p.addRequired('filename', @iscellstr);
      %p.addRequired('pathname', @iscellstr);
      
      %p.addParamValue('filetype', 'text', @ischar);
      p.addParamValue('time', 'on', @ischar);
      p.addParamValue('timeunit', 1E-3, @isnumeric); % milliseconds by default
      p.addParamValue('elabel', 'on', @ischar);
      p.addParamValue('pointat', 'column', @ischar);
      p.addParamValue('srate', 1E3, @isnumeric); % milliseconds by default
      p.addParamValue('xlim', [-200 800], @isnumeric); % milliseconds by default
      
      p.parse(varargin{:});
      
      if strcmpi(p.Results.time, 'on');
            includetime = 1;
      else
            includetime = 0;
      end
      if ismember({lower(p.Results.pointat)}, {'col','column','columns'});
            transpose = 1;
      elseif ismember({lower(p.Results.pointat)}, {'row','rows'});
            transpose = 0;
      else
            error('ERPLAB says: ?')
      end
      if strcmpi(p.Results.elabel, 'on');
            elabel = 1;
      else
            elabel = 0;
      end
      
      timeunit = p.Results.timeunit;
      
      if includetime==1
            fs   = [];
            xlim = [];
      else
            fs   = p.Results.srate;
            xlim = p.Results.xlim;
      end
end

if ~iscell(filename)
      filename = cellstr(filename);
end
if ~iscell(filetype)
      filetype = cellstr(filetype);
end

nfile = length(filename);
npath = length(pathname);
nftyp = length(filetype);

if nftyp==1 && nfile>1
      filetype = repmat(filetype,1,nfile);
end

if npath~=1 && npath~=nfile
      error('ERPLAB says: filename and pathname are uneven.')
else
      if npath==1 && nfile>1
            pathname = repmat(pathname,1,nfile);
      end
end

uftype  = unique(filetype);
nuftype = length(uftype);

if nuftype==1
      if ismember({lower(char(uftype))}, {'txt','.txt','text','.asc','asc','ascii'});   %filetype==1
            [ERPx serror] = asc2erp(filename, pathname, transpose, includetime, elabel, timeunit, fs, xlim);
            
            if serror==1
                  msgboxText =  ['Something went wrong\n'...
                        'Please, verify the file format.\n\n'...
                        'For text file, please check the organization of the data values,\n'...
                        'for instance, channels x points or points x channels,\n'...
                        'as well as the presence of both time values and electrode labels.'];
                  title = 'ERPLAB: pop_importerp few inputs';
                  errorfound(sprintf(msgboxText), title);
                  return
            end
            if serror==2
                  msgboxText ='The specified sample rate is more than 10%% off from the computed sample rate.\n';              
                  title = 'ERPLAB: pop_importerp few inputs';
                  errorfound(sprintf(msgboxText), title);
                  return
            end

      elseif ismember({lower(char(uftype))}, {'avg','.avg','neuro','neuroscan'}); %filetype==2
            ERPx = neuro2erp(filename, pathname);
      else
            error('wrong data format for importing')
      end
else
      for i=1:nfile
            if ismember({lower(filetype{i})}, {'txt','.txt','text','.asc','asc','ascii'});   %filetype==1
                  [ALLERPX(i) serror]= asc2erp(filename(i), pathname(i), transpose, includetime, elabel, timeunit, fs, xlim);
                  
                  if serror==1
                        msgboxText =  ['Something went wrong\n'...
                              'Please, verify the file format.\n\n'...
                              'For text file, please check the organization of the data values,\n'...
                              'for instance, channels x points or points x channels,\n'...
                              'as well as the presence of both time values and electrode labels.'];
                        title = 'ERPLAB: pop_importerp few inputs';
                        errorfound(sprintf(msgboxText), title);
                        return
                  end
                  if serror==2
                        msgboxText ='The specified sample rate is more than 10%% off from the computed sample rate.\n';
                        title = 'ERPLAB: pop_importerp few inputs';
                        errorfound(sprintf(msgboxText), title);
                        return
                  end
                  
            elseif ismember({lower(filetype{i})}, {'avg','.avg','neuro','neuroscan'}); %filetype==2
                  ALLERPX(i) = neuro2erp(filename(i), pathname(i));
            else
                  error('wrong data format for importing')
            end
      end
      %       ERP  = pop_appenderp(ALLERPX,1:nfile);
      [ERPx serror] = appenderp(ALLERPX,1:nfile);
      clear ALLERPX
      
      if serror==1
            msgboxText =  'Your ERPs do not have the same amount of channels!';
            title = 'ERPLAB: pop_appenderp() error:';
            errorfound(msgboxText, title);
            return
      elseif serror==2
            msgboxText =  'Your ERPs do not have the same amount of points!';
            title = 'ERPLAB: pop_appenderp() error:';
            errorfound(msgboxText, title);
            return
%       else
%             msgboxText =  'Error: Your ERPs are not compatibles!';
%             title = 'ERPLAB: pop_appenderp() error:';
%             errorfound(msgboxText, title);
%             return
      end
end

if nargin<1
      %[ERPx issave] = pop_savemyerp(ERPx,'gui','erplab');
      [ERPx issave erpcom_save] = pop_savemyerp(ERPx,'gui','erplab');
      
      if issave>0
            ERP=ERPx;
            erpcom = 'ERP = pop_importerp();';            
            %             if nfile>1
            %                   erpcom = sprintf('ERP = pop_importerp( {');
            %
            %                   for j=1:nfile;
            %                         erpcom = sprintf('%s ''%s''  ', erpcom, filename{j} );
            %                   end
            %
            %                   erpcom = sprintf('%s },{', erpcom);
            %
            %                   for j=1:npath
            %                         erpcom = sprintf('%s ''%s'');', erpcom, pathname{j} );
            %                   end
            %
            %                   erpcom = sprintf('%s});', erpcom);
            %             else
            %                   erpcom = sprintf('ERP = pop_importerp( {''%s''}, {''%s''});', char(filename), char(pathname));
            %             end
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
            disp('Warning: Your ERP structure has not yet been saved')
            disp('user canceled')
            return
      end
end
