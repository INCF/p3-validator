% pop_basicfilter 
%
% PURPOSE  :	Filters EEG data
% 
% FORMAT   :
% 
% >> EEG = pop_basicfilter( EEG, chanArray, locutoff, hicutoff,filterorder, 
% typef, remove_dc, boundarycode );
% 
% EXAMPLE  :
% 
% >> EEG = pop_basicfilter( EEG, 1:38, 0.1, 30, 2, ?butter?, 1,'boundary');
% 
% INPUTS   :
% 
% EEG           - input dataset
% chanArray     - channel index(es) where the filter will be applied.
% locutoff      - lower edge of the frequency pass band (Hz){0 -> lowpass}
% hicutoff      - higher edge of the frequency pass band (Hz) 
%                 {0 -> highpass}
% filterorder   - length of the filter in points 
%                   {default 3*fix(srate/locutoff)}
% typef         - type of filter. 'butter'=IIR Butterworth,'fir'=windowed                                                                            linear-phase FIR, 'notch'=PM Notch
% remove_dc		- 1=remove mean value of data. 0 = keep as it is.
% boundarycode 	- string 'boundary' or a numeric event code(s)
% 
% 
% OUTPUTS  :
% 
% EEG           - (filtered) output dataset
%
%
% GUI: basicfilterGUI2.m ; SUBROUTINE: basicfilter.m
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


function [EEG, com] = pop_basicfilter( EEG, chanArray, locutoff, hicutoff, filterorder, typef, remove_dc, boundary)

com = '';

if exist('filtfilt','file') ~= 2
      msgboxText{1} =  'cannot find the signal processing toolbox';
      title = 'ERPLAB: pop_basicfilter() error';
      errorfound(msgboxText, title);
      return
end
if nargin < 1
      help pop_basicfilter
      return
end
if isempty(EEG(1).data)
      msgboxText{1} =  'cannot filter an empty dataset';
      title = 'ERPLAB: pop_basicfilter() error';
      errorfound(msgboxText, title);
      return
end
if nargin==1
      
      if iserpstruct(EEG(1)) % for erpset
            nchan = EEG(1).nchan;
      else
            nchan = EEG(1).nbchan;
      end    
      
      defx = {0 30 2 1:nchan 'butter' 0 []};
      def  = erpworkingmemory('pop_basicfilter');
      
      if isempty(def)
            def = defx;
      else                        
            def{4} = def{4}(ismember(def{4},1:nchan));
      end      
      
      %
      % Opens a GUI
      %
      answer = basicfilterGUI2(EEG(1), def);
      
      if isempty(answer)
            disp('User selected Cancel')
            return
      end
      
      locutoff    = answer{1}; % for high pass filter
      hicutoff    = answer{2}; % for low pass filter
      filterorder = answer{3};
      chanArray   = answer{4};
      typef       = answer{5};
      remove_dc   = answer{6};
      boundary    = answer{7};            
      erpworkingmemory('pop_basicfilter', answer(:)');   
      
else      
      if nargin>1 && nargin<4
            error('ERPLAB says: error at pop_basicfilter(). You have to specify 4 inputs, at least.')
      end
      if nargin<8
            boundary  = [];
      end
      if nargin<7
            remove_dc = 0;
      end
      if nargin<6
            typef = 'butter'; %butterworth
      end
      if nargin<5
            filterorder = 1;
      end
end

if ischar(typef)
      [ax tt] = ismember({lower(typef)},{'butter' 'fir' 'notch'});
else
      [ax tt] = ismember(typef,[0 1 2]);
end
if tt>0
      typefnum = tt-1;  % 0=butter, 1=fir, 2=notch
else
      error('ERPLAB says: Unrecognizable filter type. See help pop_basicfilter')
end

numchan = length(chanArray);
iserrch = 0;

if iserpstruct(EEG(1)) % for erpset
      if numchan>EEG(1).nchan
            iserrch = 1;
      end
elseif iseegstruct(EEG(1))
      if numchan>EEG(1).nbchan
            iserrch = 1;
      end
else
      msgboxText =  ['Unknow data structure.\n'...
            'pop_basicfilter() only works with EEGLAB and ERPLAB structures.'];
      title = 'ERPLAB: pop_basicfilter() error:';
      errorfound(sprintf(msgboxText), title);
      return
end
if iserrch
      msgboxText{1} =  'You do not have such amount of channels in your data!';
      title = 'ERPLAB: basicfilter() error:';
      errorfound(msgboxText, title);
      return
end
if locutoff == 0 && hicutoff == 0
      disp('I beg your pardon?')
      return
end

%
% process multiple datasets April 13, 2011 JLC
%
options1 = { chanArray, locutoff, hicutoff, filterorder, typef, remove_dc, boundary };
if length(EEG) > 1
   [ EEG com ] = eeg_eval( 'pop_basicfilter', EEG, 'warning', 'on', 'params', options1);
   return;
end;

chanArraystr = vect2colon(chanArray);
options2 = { chanArray, locutoff, hicutoff, filterorder, typefnum, remove_dc, boundary };
[EEG ferror] = basicfilter( EEG, options2{:});

%
% check for filter errors
%
if ferror==1
      fprintf('\nThe filtering process has been terminated.\n\n')
      return
end
EEG.icaact = [];
if ischar(boundary)
      boundaryval = ['''' boundary ''''];
else
      if ~isempty(boundary)
            boundaryval = num2str(boundary);
      else
            boundaryval = '[]';
      end
end
com = sprintf( '%s = pop_basicfilter( %s, %s, %s, %s, %s, ''%s'', %s, %s );', inputname(1), inputname(1), ...
      chanArraystr, num2str( locutoff), num2str( hicutoff), num2str( filterorder ), typef, ...
      num2str( remove_dc ), boundaryval);
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return