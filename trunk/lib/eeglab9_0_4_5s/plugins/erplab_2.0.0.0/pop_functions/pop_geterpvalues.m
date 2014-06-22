% pop_geterpvalues
% 
% PURPOSE  :	Measures values from ERPset data (Instantaneous amplitude,
% mean amplitude, peak amplitude, etc.)
% 
% FORMAT   :
% 
% >> pop_geterpvalues(ERP, fname, latency, chanArray, op, dig)
% 
% EXAMPLE  :
% 
% pop_geterpvalues( ALLERP, 0, 1, 1, 'Baseline', 'pre', 'Erpsets', 1, 
% 'Filename', 'test.txt', 'Foutput', 'erpset', 'Fracreplace', 'NaN', 
% 'IncludeLat', 'no', 'Measure', 'instabl', 'Resolution', 3, 'Warning', 
% 'on' );                                                                                                                                                                                                                                                                                                                       
% 
% INPUTS   :
% 
% ERP			- ERP structure
% Fname			- name of text file for output. e.g. 'S03_N100_peak.txt'
% Latency		- one or two latencies in msec. e.g. [80 120]
% chanArray             - index(es) of channel(s) from which values will be 
%                         extracted. e.g. [10 2238 39 40] 
% op                    - option. Any of these:
% 
% 'instabl'             - finds the relative-to-baseline instantaneous value at the 
%                         specified latency.
% 'peakbl'              - finds the relative-to-baseline peak (or valley) value 
%                         between two latencies.
% 'meanbl'              - calculates the relative-to-baseline mean amplitude value 
%                         between two latencies.
% 'area'		- calculates the area under the curve value between two 
%                         latencies.
% 'areaz'               - calculates the area under the curve value. Lower and 
%                         upper limit of integration area automatically found with a 
%                         user defined “seed” latency. Seed latency is located between 
%                         the zero-crossing points, which erplab will calculate. 
% 
% If you do not specify an option, the default settings are as follows:
% 
% 1) If only one latency is specified, VALUES will only contain the 
% instantaneous value at that latency. 
% 2) If you specify two latencies, geterpvalues will use op = 'mean' by 
% default
% 
% dig           - number of digits to use, for precision, used to write the 
%               text file for output. Default is 4
% 
% OUTPUTS  :
% 
% text file- text file containing formatted values.
% Note: geterpvalues() use always all bins.
%
%
% GUI: geterpvaluesGUI2.m ; SUBROUTINES: geterpvalues.m, exportvalues2xls.m, exportvaluesV2.m
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
%
% BUGs and Improvements :
% ----------------------
% Measurement label option included. Suggested by Paul Kieffaber
% Local peak bug (when multiple peaks) fixed. Thanks Tanya Zhuravleva
%

function [Amp Lat erpcom] = pop_geterpvalues(ALLERP, latency, binArray, chanArray, varargin)

erpcom = '';
Amp = [];
Lat = [];

if nargin<1
      help pop_geterpvalues
      return
end
if nargin==1  % GUI
      if isstruct(ALLERP)
            cond1 = iserpstruct(ALLERP(1));
            if ~cond1
                  ALLERP = [];
            end
      else
            ALLERP = [];
      end
      
      def  = erpworkingmemory('pop_geterpvalues');
      if isempty(def)
            if isempty(ALLERP)
                  inp1   = 1; %from hard drive
                  erpset = [];
            else
                  inp1   = 0; %from hard drive
                  erpset = 1:length(ALLERP);
            end
            
            def = {inp1 erpset '' 0 1 1 'instabl' 1 3 'pre' 0 1 5 0 0.5 0 0 0 '' 0};
      else
            if ~isempty(ALLERP)
                  cerpi  = evalin('base', 'CURRENTERP'); % current erp index
                  def{2} = unique([cerpi def{2}(def{2}~=cerpi)]);
            end
      end
      
      %
      % GUI
      %
      instr = geterpvaluesGUI2(ALLERP, def);% open a GUI
      
      if isempty(instr)
            disp('User selected Cancel')
            return
      end
      
      optioni    = instr{1}; %1 means from hard drive, 0 means from erpsets menu
      erpset     = instr{2};
      fname      = instr{3};
      latency    = instr{4};
      binArray   = instr{5};
      chanArray  = instr{6};
      moption    = instr{7}; % option: type of measurement ---> instabl, meanbl, peakampbl, peaklatbl, area, areaz, or errorbl.
      coi        = instr{8};
      dig        = instr{9};
      blc        = instr{10};
      binlabop   = instr{11}; % 0: bin number as bin label, 1: bin descriptor as bin label for table.
      polpeak    = instr{12}; % local peak polarity
      sampeak    = instr{13}; % number of samples (one-side) for local peak detection criteria
      locpeakrep = instr{14}; % 1 abs peak , 0 Nan
      frac       = instr{15};
      fracmearep = instr{16}; % 1 zero , 0 Nan
      send2ws    = instr{17}; % send measurements to workspace
      appfile    = instr{18}; % 1 means append file  (it wont get into wmemory), 3 means call filter GUI
      foutput    = instr{19};
      mlabel     = instr{20};
      inclate    = instr{21}; % include used latency values for measurements like mean, peak, area...
      
      if optioni==1 % from files
            filelist    = erpset;
            disp(['pop_geterpvalues(): For file-List, user selected ', filelist])
            fid_list    = fopen( filelist );
            inputfnamex = textscan(fid_list, '%[^\n]','CommentStyle','#');
            inputfname  = cellstr(char(inputfnamex{:}));
            fclose(fid_list);
      else % from erpsets
            erpsetArray  = erpset;
      end
      if strcmpi(fname,'no_save.no_save')
            fnamer = '';
      else
            fnamer = fname;
      end
      if send2ws
            s2ws = 'on'; % send to workspace
      else
            s2ws = 'off';
      end
      
      erpworkingmemory('pop_geterpvalues', {optioni, erpset, fnamer, latency,...
            binArray, chanArray, moption, coi, dig, blc, binlabop, polpeak,...
            sampeak, locpeakrep, frac, fracmearep, send2ws, foutput, mlabel, inclate});
      
      if binlabop==0
            binlabopstr = 'off';
      else
            binlabopstr = 'on';
      end
      if polpeak==0
            polpeakstr = 'negative';
      else
            polpeakstr = 'positive';
      end
      if locpeakrep==0
            locpeakrepstr = 'NaN';
      else
            locpeakrepstr = 'absolute';
      end
      if fracmearep==0
            fracmearepstr = 'NaN';
      else
            if ismember({moption}, {'fareatlat', 'fninteglat','fareaplat','fareanlat'})
                  fracmearepstr = 'errormsg';
            else
                  fracmearepstr = 'absolute';
            end
      end
      if appfile
            appfstr = 'on';
      else
            appfstr = 'off';
      end
      if foutput
            foutputstr = 'measurement';
      else
            foutputstr = 'erpset';
      end
      if inclate
            inclatestr = 'yes';
      else
            inclatestr = 'no';
      end
      
      [Amp Lat erpcom] = pop_geterpvalues(ALLERP, latency, binArray, chanArray,...
            'Erpsets', erpset, 'Measure', moption, 'Component', coi, 'Resolution',...
            dig, 'Baseline', blc, 'Binlabel', binlabopstr, 'Peakpolarity',...
            polpeakstr, 'Neighborhood', sampeak, 'Peakreplace', locpeakrepstr,...
            'Filename', fname, 'Warning','on', 'SendtoWorkspace', s2ws, 'Append',...
            appfstr, 'Foutput', foutputstr,'Afraction', frac, 'Mlabel', mlabel,...
            'Fracreplace', fracmearepstr,'IncludeLat', inclatestr);
      
      pause(0.1)
      return
else
      p = inputParser;
      p.FunctionName  = mfilename;
      p.CaseSensitive = false;
      p.addRequired('ALLERP');
      p.addRequired('latency',  @isnumeric);
      p.addRequired('binArray', @isnumeric);
      p.addRequired('chanArray',@isnumeric);
      
      p.addParamValue('Erpsets', 1); % erpset index or input file
      p.addParamValue('Measure', '', @ischar);
      p.addParamValue('Component', 0, @isnumeric); % overlapped component ignored
      p.addParamValue('Resolution', 3, @isnumeric);
      p.addParamValue('Baseline', 'pre');
      p.addParamValue('Binlabel', 'off', @ischar);
      p.addParamValue('Peakpolarity', 'positive', @ischar); % normal | reverse
      p.addParamValue('Neighborhood', 0, @isnumeric);
      p.addParamValue('Peakreplace', 'NaN');
      p.addParamValue('Fracreplace', 'NaN');
      p.addParamValue('Warning', 'off', @ischar);
      p.addParamValue('Filename', 'tempofile.txt', @ischar); %output file
      p.addParamValue('Append', 'off', @ischar); %output file
      p.addParamValue('Afraction', 0.5, @isnumeric); %output file
      p.addParamValue('Foutput', 'measurement', @ischar); %output format
      p.addParamValue('IncludeLat', 'no', @ischar); %output format
      p.addParamValue('SendtoWorkspace', 'off', @ischar);
      p.addParamValue('Mlabel', '', @ischar);
      
      try
            p.parse(ALLERP, latency, binArray, chanArray, varargin{:});
            erpsetArray  = p.Results.Erpsets;
            cond1 = iserpstruct(ALLERP);
            cond2 = isnumeric(erpsetArray);
            
            if cond1 && cond2
                  erpsetArray  = p.Results.Erpsets;
                  nfile        = length(erpsetArray);
                  optioni      = 0; % from erpset menu or ALLERP struct
            else
                  if ischar(erpsetArray)
                        filelist = p.Results.Erpsets;
                        disp(['For file-List, user selected ', filelist])
                        fid_list    = fopen( filelist );
                        inputfnamex = textscan(fid_list, '%[^\n]','CommentStyle','#');
                        inputfname  = cellstr(char(inputfnamex{:}));
                        nfile       = length(inputfname);
                        fclose(fid_list);
                        optioni     = 1; % from file
                  else
                        error('ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ')
                  end
            end
            
            fname    = p.Results.Filename;
            localrep = p.Results.Peakreplace;
            fraclocalrep = p.Results.Fracreplace;
            frac     = p.Results.Afraction; % for fractional area latency, any value from 0 to 1
            mlabel   = p.Results.Mlabel; % label for measurement
            mlabel   = strtrim(mlabel);
            mlabel   = strrep(mlabel, ' ', '_');
            
            if ~isempty(frac)
                  if frac<0 || frac>1
                        error('ERPLAB says: error at pop_geterpvalues(). Fractional area value must be between 0 and 1')
                  end
            end
            if ischar(localrep)
                  lr = str2num(localrep);
                  if isempty(lr)
                        if strcmpi(localrep,'absolute')
                              locpeakrep = 1;
                        else
                              error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' localrep])
                        end
                  else
                        if isnan(lr)
                              locpeakrep = 0;
                        else
                              error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' localrep])
                        end
                  end
            else
                  if isnan(localrep)
                        locpeakrep = 0;
                  else
                        error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' num2str(localrep(1))])
                  end
            end
            if ischar(fraclocalrep)
                  
                  flr = str2num(fraclocalrep);
                  
                  if isempty(flr)
                        if strcmpi(fraclocalrep,'absolute')
                              fracmearep = 1;
                        elseif strcmpi(fraclocalrep,'error') || strcmpi(fraclocalrep,'errormsg')
                              fracmearep = 2; % shows error message. Stop measuring.
                        else
                              error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' fraclocalrep])
                        end
                  else
                        if isnan(flr)
                              fracmearep = 0;
                        else
                              error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' fraclocalrep])
                        end
                  end
            else
                  if isnan(fraclocalrep)
                        fracmearep = 0;
                  else
                        error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' num2str(fraclocalrep(1))])
                  end
            end
            
            sampeak     = p.Results.Neighborhood; % samples around the peak
            
            if strcmpi(p.Results.Peakpolarity, 'positive')
                  polpeak = 1; % positive
            elseif strcmpi(p.Results.Peakpolarity, 'negative')
                  polpeak = 0;
            else
                  error(['ERPLAB says: error at pop_geterpvalues(). Unrecognizable input ' p.Results.Peakpolarity]);
            end
            if strcmpi(p.Results.Binlabel, 'on')
                  binlabop = 1; % bin descriptor as bin label for table
            elseif strcmpi(p.Results.Binlabel, 'off')
                  binlabop = 0; % bin# as bin label for table
            else
                  error(['ERPLAB says: Unrecognizable input ' p.Results.Binlabel]);
            end
            
            blc     = p.Results.Baseline;
            dig     = p.Results.Resolution;
            coi     = p.Results.Component;
            moption = p.Results.Measure;
            
            if isempty(moption)
                   error('ERPLAB says: User must specify a type of measurement.')
            end
            
            if ismember({moption}, {'instabl', 'areazt','areazp','areazn', 'nintegz'});
                  if length(latency)~=1
                        error(['ERPLAB says: ' moption ' only needs 1 latency value.'])
                  end
            else
                  if length(latency)~=2
                        error(['ERPLAB says: ' moption ' needs 2 latency values.'])
                  else
                        if latency(1)>=latency(2)
                              msgboxText = ['For latency range, lower time limit must be on the left.\n'...
                                    'Additionally, lower time limit must be at least 1/samplerate seconds lesser than the higher one.'];
                              title = 'ERPLAB: pop_geterpvalues() inputs';
                              errorfound(sprintf(msgboxText), title);
                              return
                        end
                  end
            end
            if strcmpi(p.Results.Warning, 'on')
                  menup = 1; % enable warning message
            else
                  menup = 0;
            end
            if strcmpi(p.Results.SendtoWorkspace, 'on')
                  send2ws = 1; % send to workspace
            else
                  send2ws = 0;
            end
            if strcmpi(p.Results.Append, 'on')
                  appendfile = 1;
            else
                  appendfile = 0;
            end
            if strcmpi(p.Results.Foutput, 'measurement')
                  foutput = 1;
            else
                  foutput = 0;
            end
            if strcmpi(p.Results.IncludeLat, 'yes') || strcmpi(p.Results.IncludeLat, 'on')
                  inclate = 1;
            else
                  inclate = 0;
            end
      catch
            serr = lasterror;
            msgboxText =  ['Please, check your inputs: \n\n'...
                  serr.message];
            tittle = 'ERPLAB: pop_geterpvalues() error:';
            errorfound(sprintf(msgboxText), tittle);
            return
      end
      if ~ismember({moption}, {'instabl', 'meanbl', 'peakampbl', 'peaklatbl', 'fpeaklat',...
                  'areat', 'areap', 'arean','areazt','areazp','areazn','fareatlat',...
                  'fareaplat','fninteglat','fareanlat', 'ninteg','nintegz' });
            
            msgboxText =  [moption ' is not a valid option for pop_geterpvalues!'];
            title = 'ERPLAB: pop_geterpvalues wrong inputs';
            errorfound(msgboxText, title);
            return
      end
end
if ischar(blc)
      blcorrstr = [''''  blc '''' ];
else
      blcorrstr = ['[' num2str(blc) ']'];
end
[pathtest, filtest, ext, versn] = fileparts(fname);
if isempty(filtest)
      error('File name is empty.')
end
if strcmpi(ext,'.xls')
      if ispc
            exceloption = 1;
            fprintf('\nOutput will be a Microsoft Excel spreadsheet file');
            warning off MATLAB:xlswrite:AddSheet
            if strcmp(pathtest,'')
                  pathtest = cd;
                  fname = fullfile(pathtest, [filtest ext]);
            end
      else
            fprintf('\nWARNING:\n');
            title      = 'ERPLAB: WARNING, pop_geterpvalues() export to Excel' ;
            question = ['The full functionality of XLSWRITE depends on the ability\n'...
                  'to instantiate Microsoft Excel as a COM server.\n'...
                  'COM is a technology developed for Windows platforms and,\n'...
                  'at the current ERPLAB version,  is not available for non-Windows machines\n\n'...
                  'Do you want to continue anyway with a text file instead?'];
            
            button = askquest(sprintf(question), title);
            if ~strcmpi(button,'yes')
                  disp('User selected Cancel')
                  return
            end
            if strcmp(pathtest,'')
                  pathtest = cd;
            end
            ext   = '.txt';
            fname = fullfile(pathtest, [filtest ext]);
            fprintf('\nOutput file will have extension %s\n', ext);
            exceloption = 0;
      end
      send_to_file = 1;
elseif strcmpi(ext,'.no_save')
      send_to_file = 0;
else
      exceloption = 0;
      if strcmp(pathtest,'')
            pathtest = cd;
      end
      if ~strcmpi(ext,'.txt')&& ~strcmpi(ext,'.dat')
            ext = '.txt';
            fname = fullfile(pathtest, [filtest ext]);
      end
      fprintf('\nOutput file will have extension %s\n', ext);
      send_to_file = 1;
end
fprintf('\nBaseline period = %s will be used for measurements\n\n', blcorrstr);
conti = 1;
Amp   = zeros(length(binArray), length(chanArray), nfile);

for k=1:nfile
      if optioni==1 % from files
            filex = load(inputfname{k}, '-mat');
            ERP   = filex.ERP;
      else          % from erpsets
            ERP = ALLERP(erpsetArray(k));
      end
      [ERP conti serror] = olderpscan(ERP, menup);
      if conti==0
            break
      end
      if serror ==1
            kindex = k;
            kname  = ERP.erpname;
            break
      end
      if k==1
            n1bin = ERP.nbin;
            n1bdesc = ERP.bindescr;
      else
            if ERP.nbin~=n1bin
                  serror = 2;
                  break
            end
            if ismember(0,ismember(lower(ERP.bindescr), lower(n1bdesc))) % May 25, 2010
                  serror = 3;
                  break
            end
      end
      
      %
      % Get measurements
      %
      fprintf('Still working...\n')
      
      if inclate
            [A lat4mea]  = geterpvalues(ERP, latency, binArray, chanArray, moption, blc, coi, polpeak, sampeak, locpeakrep, frac, fracmearep);
      else
            A = geterpvalues(ERP, latency, binArray, chanArray, moption, blc, coi, polpeak, sampeak, locpeakrep, frac, fracmearep);
            lat4mea = [];
      end
      if isempty(A)
            errmsg = 'Empty outcome.';
            serror = 4;
            break
      end
      if ischar(A)
            errmsg = A;
            serror = 4;
            break
      end
      if send_to_file
            if exceloption
                  %
                  % Excel
                  %
                  exportvalues2xls(ERP, {A}, binArray,chanArray, 0, moption, fname, k+appendfile)
            else
                  %
                  % Text
                  %
                  % (ERP, values, binArray, chanArray, fname, dig, ncall, binlabop, formatout, mlabel, lat4mea)
                  exportvaluesV2(ERP, {A}, binArray, chanArray, fname, dig, k+appendfile, binlabop, foutput, mlabel, lat4mea)
            end
            
            prew = 'Additionally, m';
      else
            prew = 'M';
      end
      Amp(:,:,k) = A;  % bin x channel x erpset
end

%
% Send measurements to workspace (from GUI)
%
if send2ws
      assignin('base','ERP_MEASURES', Amp);
      fprintf('%seasured values were sent to Workspace as ERP_MEASURES.\n', prew);
end
if conti==0
      return
end
if serror ==1
      msgboxText =  sprintf('A problem was found at ERPset %s (%gth).', kname, kindex);
      title = 'ERPLAB: pop_geterpvalues';
      errorfound(msgboxText, title);
      return
end
if serror ==2
      msgboxText = ['Number of bins is different across datasets .\n'...
            'You must use ERPset related to the same experiment.'];
      title = 'ERPLAB: pop_geterpvalues';
      errorfound(sprintf(msgboxText), title);
      return
end
if serror ==3
      msgboxText = ['The bin description set among datasets is different.\n'...
            'You must use ERPset related to the same experiment.'];
      title = 'ERPLAB: pop_geterpvalues';
      errorfound(sprintf(msgboxText), title);
      return
end
if serror ==4
      msgboxText = ['Sorry, something went wrong.\n\n'...
            errmsg '\n\n'...
            'Please, check your inputs:\n'...
            'For instance, invalid latency/bin/channel range; empty, flat, or zero bindata, etc.\n'];
      tittle = 'ERPLAB: geterpvalues() error:';
      errorfound(sprintf(msgboxText), tittle);
      return
end

%
% command history
%
binArraystr  = vect2colon(binArray);
chanArraystr = vect2colon(chanArray);
latencystr   = vect2colon(latency);

if isstruct(ALLERP)
      DATIN =  inputname(1);
else
      DATIN = ['''' ALLERP ''''];
end
skipfields = {'ALLERP', 'latency', 'binArray','chanArray', 'Component'};
if ~ismember({moption}, {'peakampbl', 'peaklatbl'})
      skipfields = [skipfields {'Neighborhood', 'Peakpolarity', 'Peakreplace'}];
end
if strcmpi(fname,'no_save.no_save') || strcmpi(fname,'tempofile.txt')
      skipfields = [skipfields {'Filename'}];
end
fn     = fieldnames(p.Results);
erpcom = sprintf( '[Amp Lat] = pop_geterpvalues( %s, %s, %s, %s ',  DATIN, latencystr, binArraystr, chanArraystr);
for q=1:length(fn)
      fn2com = fn{q};
      if ~ismember(fn2com, skipfields)
            fn2res = p.Results.(fn2com);
            if ~isempty(fn2res)
                  if ischar(fn2res)
                        if ~strcmpi(fn2res,'off')
                              erpcom = sprintf( '%s, ''%s'', ''%s''', erpcom, fn2com, fn2res);
                        end
                  else
                        erpcom = sprintf( '%s, ''%s'', %s', erpcom, fn2com, vect2colon(fn2res,'Repeat','on'));
                  end
            end
      end
end
erpcom = sprintf( '%s );', erpcom);
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return
