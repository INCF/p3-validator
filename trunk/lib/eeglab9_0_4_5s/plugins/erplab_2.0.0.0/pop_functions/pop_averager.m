% pop_averager  
% 
% PURPOSE  :	Averages bin-epoched EEG dataset(s)
% 
% FORMAT   :
% 
% >> ERP = pop_averager( ALLEEG, setindex, artcrite, stdev ); 
% 
% EXAMPLE :
% 
% >> ERP = pop_averager(ALLEEG, 1:5, 1, 1);
% 
% INPUTS     :
% 
% ALLEEG (or EEG)	- bin-epoched dataset(s)
% setindex              - dataset index(ices) when dataset(s) are contained within the ALLEEG structure. For single bin-epoched dataset within EEG structure this value must be equal to 1 
% Artcrite              - Inclusion / exclusion of marked epochs during artifact  detection: 1=yes; 0=no; 2=include ONLY marked epochs
% stdev                 - Get standard deviation. 1=yes; 0=no
% 
% 
% OUTPUTS
% 
% ERP 	- data structure containing the average of all specified dataset(s).
%
%
% GUI: averagerGUI.m ; SUBROUTINE: averager.m
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

function [ERP erpcom] = pop_averager(ALLEEG, setindex, artcrite, stdev)

erpcom = '';
ERP = preloadERP;

if nargin < 1
      help pop_averager
      return
end
if nargin > 4
      error('ERPLAB says: pop_averager() works with 4 arguments max!')
end
nloadedset = length(ALLEEG);
if nargin==1      
      currdata = evalin('base', 'CURRENTSET');
      if currdata==0
            msgboxText =  'pop_averager() error: cannot average an empty dataset!!!';
            title      = 'ERPLAB: No data';
            errorfound(msgboxText, title);
            return
      end      
      def  = erpworkingmemory('pop_averager');
      if isempty(def)
            def = {1 1 1 1};
      end
      
      %
      % epochs per dataset
      %
      nepochperdata = zeros(1, length(ALLEEG));
      for k=1:length(ALLEEG)
            nepochperdata(k) = ALLEEG(k).trials;
      end
      if ischar(def{end});if (strcmpi(def{end},'steve')|| strcmpi(def{end},'javier'));gop=1;else gop=0;end;else gop=0;end
      if gop, answer = averagerxGUI(currdata, def, nepochperdata); else answer = averagerGUI(currdata, def, nepochperdata);end
      if isempty(answer)
            disp('User selected Cancel')
            return
      end      
      setindex = answer{1};   % datasets to average
      
      %
      % Artifact rejection criteria for averaging
      %
      %  artcrite = 0 --> averaging all (good and bad trials)
      %  artcrite = 1 --> averaging only good trials
      %  artcrite = 2 --> averaging only bad trials
      %  artcrite is cellarray  --> averaging only specified epoch indices
      artcrite  = answer{2};
      
      %
      % Weighted average option. 1= yes, 0=no
      %
      %wavg     = answer{3};
      
      %
      % Standard deviation option. 1= yes, 0=no
      %
      stdev     = answer{4};
      setindexstr = vect2colon(setindex);
      def(1:4) = {setindex, artcrite, 1, stdev};      
      erpworkingmemory('pop_averager', def);
else
      if nargin<4
            stdev=0; % no standard deviation by default
      end
      %if nargin<4
      %      wavg=0;  % no weighted average, by default
      %end
      
      if nargin<3
            artcrite = 1; % averaging only good trials by default
      end
      
      setindexstr = vect2colon(setindex);
end

wavg = 1; % weighted average
nset       = length(setindex);     % all selected sets
nrsetindex = unique(setindex);     % set index but without repetitions!
nrnset     = length(nrsetindex);   % N of setindex but without repetitions!
setindex   = nrsetindex;           % set index upgraded

if nset > nrnset
      msgboxText =  'Repeated dataset index will be ignored!';
      title      = 'ERPLAB: pop_averager() WARNING';
      errorfound(msgboxText, title);
end

nset     = length(setindex);  % nset  upgraded

if nset > nloadedset
      msgboxText =  ['Hey!  There are not ' num2str(nset) ' datasets, but ' num2str(nloadedset) '!'];
      title      = 'ERPLAB: pop_averager() Error';
      errorfound(msgboxText, title);
      return
end
if max(setindex) > nloadedset
      igrtr       = setindex(setindex>nloadedset);
      indxgreater = num2str(igrtr);
      
      if length(igrtr)==1
            msgboxText{1} =  ['Hey!  dataset #' indxgreater ' does not exist!'];
      else
            msgboxText{1} =  ['Hey!  dataset #' indxgreater ' do not exist!'];
      end
      
      title = 'ERPLAB: pop_averager() Error';
      errorfound(msgboxText, title);
      return
end
if nset==1 && wavg
        %fprintf('\n********************************************************************\n')
        %fprintf('NOTE: Weighted averaging is only available for multiple datasets.\n')
        %fprintf('      ERPLAB will perform a classic averaging over this single dataset.\n')
        %fprintf('********************************************************************\n\n')
elseif nset>1 && wavg
        fprintf('\n********************************************************************\n')
        fprintf('NOTE: Multiple datasets are being averaged together.\n')
        fprintf('Weighted averaging will be performed (each trial will be treated equally, as if all trials were in a single dataset).\n')
        fprintf('********************************************************************\n\n')
end

cversion = geterplabversion;

for i=1:nset
      if isempty(ALLEEG(setindex(i)).epoch)
            msgboxText =  ['You should epoch your dataset #' ...
                  num2str(setindex(i)) ' before perform averager.m'];
            title = 'ERPLAB: pop_averager() Error';
            errorfound(msgboxText, title);
            return
      end
      if isempty(ALLEEG(setindex(i)).data)
            errormsg = ['ERPLAB says: pop_averager() error cannot average an empty dataset: ' num2str(setindex(i))];
            error(errormsg)
      end
      if ~isfield(ALLEEG(setindex(i)),'EVENTLIST')
            msgboxText =  'You should create/add a EVENTLIST before perform Averaging!';
            title      = 'ERPLAB: pop_averager() Error';
            errorfound(msgboxText, title);
            return
      end
      if isempty(ALLEEG(setindex(i)).EVENTLIST)
            msgboxText =  'You should create/add a EVENTLIST before perform Averaging!';
            title      = 'ERPLAB: pop_averager() Error';
            errorfound(msgboxText, title);
            return
      end
      if ~strcmp(ALLEEG(setindex(i)).EVENTLIST.version, cversion) && nargin==1
            
            question = ['WARNING: Dataset %g was created from a different ERPLAB version.\n'...
                  'ERPLAB will try to make it compatible with the current version.\n\n'...
                  'Do you want to continue?'];
            title    = ['ERPLAB: erp_loaderp() for version: ' ALLEEG(setindex(i)).EVENTLIST.version] ;
            button = askquest(sprintf(question, setindex(i)), title);
            
            if ~strcmpi(button,'yes')
                  disp('User selected Cancel')
                  return
            end
      elseif ~strcmp(ALLEEG(setindex(i)).EVENTLIST.version, cversion) && nargin>1
            fprintf('\n\nWARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING\n')
            fprintf('ERPLAB: pop_averager() detected version %s\n', ALLEEG(setindex(i)).EVENTLIST.version);
            fprintf('Dataset #%g was created from an older ERPLAB version\n\n', setindex(i));
      end
end

pause(0.1);

if nset>1
      
      %
      % basic test for number of channels (for now...)19 sept 2008
      %
      totalchannelA = sum(cell2mat({ALLEEG(setindex).nbchan}));  % fixed october 03, 2008 JLC
      totalchannelB = (cell2mat({ALLEEG(setindex(1)).nbchan}))*nset;  % fixed october 03, 2008 JLC
      
      if totalchannelA~=totalchannelB
            msgboxText =  'Datasets have different number of channels!';
            title      = 'ERPLAB: pop_averager() Error';
            errorfound(msgboxText, title);
            return
      end
      
      %
      % basic test for number of points (for now...)19 sept 2008
      %
      totalpointA = sum(cell2mat({ALLEEG(setindex).pnts})); % fixed october 03, 2008 JLC
      totalpointB = (cell2mat({ALLEEG(setindex(1)).pnts}))*nset; % fixed october 03, 2008 JLC
      
      if totalpointA ~= totalpointB
            msgboxText =  'Datasets have different number of points!';
            title      = 'ERPLAB: pop_averager() Error';
            errorfound(msgboxText, title);
            return
      end
      
      %
      % basic test for time axis (for now...)
      %
      tminB = ALLEEG(setindex(1)).xmin;
      tmaxB = ALLEEG(setindex(1)).xmax;
      
      for j=2:nset            
            tminA = ALLEEG(setindex(j)).xmin;
            tmaxA = ALLEEG(setindex(j)).xmax;
            
            if tminA ~= tminB || tmaxA~=tmaxB
                  msgboxText =  'Datasets have different time axis!';
                  title      = 'ERPLAB: pop_averager() Error';
                  errorfound(msgboxText, title);
                  return
            end
      end
      
      %
      % basic test for channel labels
      %
      labelsB = {ALLEEG(setindex(1)).chanlocs.labels};
      
      for j=2:nset
            
            labelsA = {ALLEEG(setindex(j)).chanlocs.labels};
            [tla, indexla] = ismember(labelsA, labelsB);
            condlab1 = length(tla)==nnz(tla);   % do both datasets have the same channel labels?
            
            if ~condlab1
                  msgboxText =  ['Datasets have different channel labels.\n'...
                        'Do you want to continue anyway?'];
                  title = 'ERPLAB: pop_averager() WARNING';
                  button = askquest(sprintf(msgboxText), title);
                  
                  if ~strcmpi(button,'yes')
                        disp('User selected Cancel')
                        return
                  end
            end            
            if isrepeated(indexla)
                  
                  fprintf('\nWARNING: Some channels have the same label.\n\n')
                  
                  if ismember(0,strcmp(labelsA, labelsB))
                        msgboxText =  ['Datasets have different channel labels.\n'...
                              'Do you want to continue anyway?'];
                        title = 'ERPLAB: pop_averager() WARNING';
                        button = askquest(sprintf(msgboxText), title);
                        
                        if ~strcmpi(button,'yes')
                              disp('User selected Cancel')
                              return
                        end
                  end
            else
                  condlab2 = issorted(indexla);       % do the channel labels match by channel number?
                  
                  if ~condlab2
                        msgboxText =  ['Channel numbering and channel labeling do not match among datasets!\n'...
                              'Do you want to continue anyway?'];
                        title = 'ERPLAB: pop_averager() WARNING';
                        button = askquest(sprintf(msgboxText), title);
                        
                        if ~strcmpi(button,'yes')
                              disp('User selected Cancel')
                              return
                        end
                  end
            end
      end
end

%
% Define ERP
%
nch  = ALLEEG(setindex(1)).nbchan;
pnts = ALLEEG(setindex(1)).pnts;
nbin = ALLEEG(setindex(1)).EVENTLIST.nbin;
histoflags = zeros(nbin,16);
flagbit    = bitshift(1, 0:15);

if nset>1      
      sumERP     = zeros(nch,pnts,nbin);      % makes a zero erp
      if stdev
            sumERP2 = zeros(nch,pnts,nbin);   % makes a zero weighted sum of squares: Sum(wi*xi^2)
      end
      oriperbin  = zeros(1,nbin);             % original number of trials per bin counter init
      tperbin    = zeros(1,nbin);
      invperbin  = zeros(1,nbin);
      workfnameArray = {[]};
      chanlocs       = [];
      
      for j=1:nset
            %
            % Multiple Dataset
            %
            %
            % Note: the standard deviation (std) for multiple epoched datasets is the std across the corresponding averages;
            % Individual stds will be lost.
            fprintf('\nAveraging dataset #%g...\n', setindex(j));
            [ERP EVENTLISTi countbiORI countbinINV countbinOK countflags workfname] = averager(ALLEEG(setindex(j)), artcrite, stdev);
            
            %
            % Checks criteria for bad subject (dataset)
            %
            TotOri = sum(countbiORI,2);
            TotOK  = sum(countbinOK,2);
            pREJ   = (TotOri-TotOK)*100/TotOri;  % Total trials rejected percentage            
            oriperbin = oriperbin + countbiORI;
            tperbin   = tperbin   + countbinOK;    % only good trials (total)
            invperbin = invperbin + countbinINV;   % invalid trials
            ALLEVENTLIST(j) = EVENTLISTi;
            
            for bb=1:nbin
                  for m=1:16
                        C = bitand(flagbit(m), countflags(bb,:));
                        histoflags(bb, m) = histoflags(bb, m) + nnz(C);
                  end
            end
            if wavg
                  for bb=1:nbin
                        sumERP(:,:,bb) = sumERP(:,:,bb)  + ERP.bindata(:,:,bb).*countbinOK(bb);
                        if stdev
                              sumERP2(:,:,bb) = sumERP2(:,:,bb)  + (ERP.bindata(:,:,bb).^2).*countbinOK(bb); % weighted sum of squares: Sum(wi*xi^2)
                        end
                  end
            else
                  sumERP = sumERP + ERP.bindata;
                  if stdev
                        sumERP2 = sumERP2 + ERP.bindata.^2;  % general sum of squares: Sum(xi^2)
                  end
            end
            
            workfnameArray{j} = workfname;
            
            if isfield(ERP.chanlocs, 'theta')
                  chanlocs = ERP.chanlocs;
            else
                  [chanlocs(1:length(ERP.chanlocs)).labels] = deal(ERP.chanlocs.labels);
            end
      end
      
      ERP.chanlocs = chanlocs;
      
      if wavg
            for bb=1:nbin
                  if tperbin(bb)>0
                        
                        ERP.bindata(:,:,bb) = sumERP(:,:,bb)./tperbin(bb); % get ERP!
                        
                        if stdev
                              fprintf('\nEstimating weighted standard deviation of data...\n');
                              insqrt = sumERP2(:,:,bb).*tperbin(bb) - sumERP(:,:,bb).^2;
                              
                              if nnz(insqrt<0)>0
                                    ERP.binerror(:,:,bb) = zeros(nch, pnts, 1);
                              else
                                    ERP.binerror(:,:,bb) = (1/tperbin(bb))*sqrt(insqrt);
                              end
                        end
                  else
                        ERP.bindata(:,:,bb) = zeros(nch,pnts,1);  % makes a zero erp
                  end
            end
      else
            ERP.bindata = sumERP./nset; % get ERP!
            if stdev
                  fprintf('\nEstimating standard deviation of data...\n');
                  ERP.binerror  = sqrt(sumERP2.*(1/nset) - ERP.bindata.^2) ; % ERP stdev
            end
      end
else
      %
      % Single Dataset
      %
      fprintf('\nAveraging  a unique dataset #%g...\n', setindex(1));
      
      %
      % Get individual average
      %
      [ERP EVENTLISTi countbiORI countbinINV countbinOK countflags workfname] = averager(ALLEEG(setindex(1)), artcrite, stdev);
      
      %
      % Checks criteria for bad subject (dataset)
      %
      TotOri = sum(countbiORI,2);
      TotOK  = sum(countbinOK,2);
      pREJ   = (TotOri-TotOK)*100/TotOri;  % Total trials rejected percentage
      
      oriperbin = countbiORI;
      tperbin   = countbinOK;  % only good trials
      invperbin = countbinINV; % invalid trials
      ALLEVENTLIST = EVENTLISTi;
      
      for bb=1:nbin
            for m=1:16
                  C = bitand(flagbit(m), countflags(bb,:));
                  histoflags(bb, m) = nnz(C);
            end
      end
      
      workfnameArray  = cellstr(workfname);
      
      %
      % Note: the standard deviation (std) for a unique epoched dataset is the std across the corresponding epochs;
      %
end

ERP.erpname   = [];
ERP.workfiles = workfnameArray;

if wavg
      fprintf('\n *** %g datasets were averaged. ***\n\n', nset);
else
      fprintf('\n *** %g datasets were averaged (arithmetic mean). ***\n\n', nset);
end

ERP.ntrials.accepted  = tperbin;
ERP.ntrials.rejected  = oriperbin - tperbin;
ERP.ntrials.invalid   = invperbin;
propexcluded          = 100*round(sum(ERP.ntrials.accepted)/(sum(ERP.ntrials.accepted)+sum(ERP.ntrials.rejected)));
ERP.propexcluded      = propexcluded;
tempflagcount         = fliplr(histoflags);          % Total per flag. Flag 1 (LSB) at the rightmost bit
ERP.ntrials.arflags   = tempflagcount(:,9:16);       % show only the less significative byte (artifact flags)
ERP.EVENTLIST         = ALLEVENTLIST;
[ERP serror]          = sorterpstruct(ERP);

if serror
      error('ERPLAB says: pop_averager() Your datasets are not compatibles')
end
if nargin==1
      [ERP issave erpcom_save] = pop_savemyerp(ERP,'gui','erplab');
      if issave>0
            if iscell(artcrite)
                  artcritestr = vect2colon(cell2mat(artcrite), 'Sort','yes','Delimiter','off');
                  erpcom = sprintf( 'ERP = pop_averager( %s, %s, {%s}, %s );', inputname(1), setindexstr,...
                        artcritestr, num2str(stdev));
            else
                  erpcom = sprintf( 'ERP = pop_averager( %s, %s, %s, %s );', inputname(1), setindexstr,...
                        num2str(artcrite), num2str(stdev));
            end            
            if issave==2
                  erpcom = sprintf('%s\n%s', erpcom, erpcom_save);
                  msgwrng = '*** Your ERPset was saved on your hard drive.***';
            else
                  msgwrng = '*** Warning: Your ERPset was only saved on the workspace.***';
            end
            fprintf('\n%s\n\n', msgwrng)
      else
            msgwrng = 'ERPLAB Warning: Your changes were not saved';
            try cprintf([1 0.52 0.2], '%s\n\n', msgwrng); catch,fprintf('%s\n\n', msgwrng);end ;
            return
      end
end

try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return


