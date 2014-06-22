% Usage
% eindices = getepochindex6(ALLEEG, setindxsetArray, binArray, nepoch, optiona)
%
%'Artifact', 'good',
%'Catching', 'odd',
%'Episode', {3 4})
% Indexing
% Instance
% Warning
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
function eindices = getepochindex6(ALLEEG, setindxsetArray, binArray, nepoch, varargin)

eindices = [];

if nargin<1
      help
      return
end

%
% Parsing inputs
%
p = inputParser;
p.FunctionName  = mfilename;
p.addRequired('ALLEEG');
p.addRequired('setindxsetArray', @isnumeric);     % e.g. [2 5]
p.addRequired('binArray', @isnumeric);            % e.g. [1:4]
p.addRequired('nepoch', @isnumeric);              % e.g. 100

p.addParamValue('Artifact', 'good', @ischar);     % e.g 'all','good','bad'
p.addParamValue('Catching', 'onthefly', @ischar); % e.g 'onthefly', 'random', 'odd', 'even'
p.addParamValue('Episode', [], @isnumeric);       % e.g. [.25 .75], proportion of recording [start end]
p.addParamValue('Indexing', 'absolute', @ischar); % e.g. 'absolute', 'relative'
p.addParamValue('Instance', 'anywhere', @ischar); % e.g. 'anywhere', 'first', 'last'
p.addParamValue('Warning', 'on', @ischar);        % e.g. 'on', 'off'
p.parse(ALLEEG, setindxsetArray, binArray, nepoch, varargin{:});

%
% additional parsing
%
ntset = length(ALLEEG); % total dataset at ALLEEG
nset  = length(setindxsetArray);
uset  = unique(setindxsetArray);

if length(uset)~=nset
      %       msgboxText =  'Repeated dataset indices were found.\n';
      %       title = 'ERPLAB: getepochindex() Error';
      %       errorfound(msgboxText, title);
      %       return
      fprintf('\nWARNING: Repeated dataset index(ices) were found.\n')
      fprintf('ERPLAB will ignore the repeated one(s).\n\n')
      
end
if max(setindxsetArray)>ntset
      msgboxText =  'dataset index(ices) out of range.\n';
      title = 'ERPLAB: getepochindex() Error';
      errorfound(msgboxText, title);
      return
end

ncurrentbin = zeros(1,nset);
nbin = length(binArray);

%
% Check number of epochs per bin
%
if length(nepoch)==1 && length(binArray)>=1
      nepoch = repmat(nepoch,1, length(binArray));
elseif length(nepoch)~=1 && length(nepoch)~=length(binArray)
      msgboxText =  'Number of epochs value must be a single value OR as many values as bins you have.\n';
      title = 'ERPLAB: getepochindex() Error';
      errorfound(msgboxText, title);
      return
end
if mod(length(p.Results.Episode),2)~=0
      msgboxText =  'Episode must have an even amount of values';
      title = 'ERPLAB: getepochindex() Error';
      errorfound(msgboxText, title);
      return
end

%
% more checking...
%
for i=1:nset
      if isempty(ALLEEG(setindxsetArray(i)).epoch)
            msgboxText =  ['You should epoch your dataset #' ...
                  num2str(setindxsetArray(i)) ' before perform getepochindex.m'];
            title = 'ERPLAB: getepochindex() Error';
            errorfound(msgboxText, title);
            return
      end
      if isempty(ALLEEG(setindxsetArray(i)).data)
            errormsg = ['ERPLAB says: getepochindex() error cannot work with an empty dataset: ' num2str(setindxsetArray(i))];
            error(errormsg)
      end
      if ~isfield(ALLEEG(setindxsetArray(i)),'EVENTLIST')
            msgboxText =  'You should create/add a EVENTLIST before perform getepochindex()!';
            title      = 'ERPLAB: getepochindex() Error';
            errorfound(msgboxText, title);
            return
      end
      if isempty(ALLEEG(setindxsetArray(i)).EVENTLIST)
            msgboxText =  'You should create/add a EVENTLIST before perform getepochindex()!';
            title      = 'ERPLAB: getepochindex() Error';
            errorfound(msgboxText, title);
            return
      end
      
      ncurrentbin(i) = ALLEEG(setindxsetArray(i)).EVENTLIST.nbin;
      
      if i>1
            if ncurrentbin(i)~=ncurrentbin(i-1)
                  msgboxText =  'Number of bins are different across specified datasets';
                  title      = 'ERPLAB: getepochindex() Error';
                  errorfound(msgboxText, title);
                  return
            end
      end
end

%
% Get the number of trials (epochs) per dataset
%
numtrials = zeros(1,nset);
for h=1:nset
      numtrials(h) = ALLEEG(setindxsetArray(h)).trials;
end

nmaxtrials = max(numtrials); % max number of trials among datasets
nmintrials = min(numtrials); % min number of trials among datasets

% get ar fields
F = fieldnames(ALLEEG(1).reject);
sfields1 = regexpi(F, '\w*E$', 'match');
sfields2 = [sfields1{:}];
fields4reject  = regexprep(sfields2,'E','');
nf = length(fields4reject);
wannago  = 1;
eindices = repmat({[]}, 1,nset);

for h=1:nset % dataset
      Tempeindices = [];
      for ibin=1:nbin % bin
            
            %
            % Get epochs indices per each specified bin
            %
            bepochArray = epoch4bin(ALLEEG(h), binArray(ibin)); % absolute epoch indices (meaning related to the beginning of the current dataset)
            
            if isempty(bepochArray)
                  error('prog:input', 'ERPLAB says: There was not found any epoch for bin %g ', ibin)
            end
            
            %
            % ARTIFACT DETECTION CRITERION
            %
            arepochindx = zeros(1,numtrials(h)); % vector for storing ar values
            
            for i=1:nf  % ar field
                  if ~isempty(ALLEEG(setindxsetArray(h)).reject.(fields4reject{i}))
                        arepochindx(i,:) = ALLEEG(setindxsetArray(h)).reject.(fields4reject{i});
                  end
            end
            
            arepochindx   = arepochindx(:,bepochArray); % artifact marks across different fields and only epochs for the current bin's epochs
            sumat         = sum(arepochindx,1);     % sum across fields
            badepochindx  = find(sumat);    % find bad epoch indices (any element higher than zero)
            goodepochindx = find(sumat==0); % find good epoch indices (any zero value element)
            
            if strcmpi(p.Results.Artifact, 'good')
                  if isempty(goodepochindx)
                        error('prog:input', 'ERPLAB says: There was not found any %s epoch for bin %g ', p.Results.Artifact, ibin)
                  end
                  selectedepochs = bepochArray(goodepochindx);
                  str4ep = 'good';
            elseif strcmpi(p.Results.Artifact, 'bad')
                  if isempty(badepochindx)
                        error('prog:input', 'ERPLAB says: There was not found any %s epoch for bin %g ', p.Results.Artifact, ibin)
                  end
                  str4ep = 'bad';
                  selectedepochs = bepochArray(badepochindx);
            elseif strcmpi(p.Results.Artifact, 'all')
                  str4ep = '';
                  selectedepochs = bepochArray;    % all
            else
                  error('prog:input', 'ERPLAB says: Unrecognizable criterion "%s"', p.Results.Artifact)
            end
            
            %
            % CATCHING
            %
            if strcmpi(p.Results.Catching, 'random') || strcmpi(p.Results.Catching, 'rand')
                  nsel = length(selectedepochs);
                  nselrindx = randperm(nsel);
                  selectedepochs = selectedepochs(nselrindx); %  random and sorted again
            elseif strcmpi(p.Results.Catching, 'odd')
                  %
                  % absolute or relative indexing?
                  %
                  if strcmpi(p.Results.Indexing, 'absolute')
                        selectedepochs = selectedepochs(logical(mod(selectedepochs,2)));
                  else % relative
                        nsel = length(selectedepochs);
                        oddindx = 1:2:nsel;
                        selectedepochs = selectedepochs(oddindx);
                  end
            elseif strcmpi(p.Results.Catching, 'even')
                  %
                  % absolute or relative indexing?
                  %
                  if strcmpi(p.Results.Indexing, 'absolute')
                        selectedepochs = selectedepochs(~logical(mod(selectedepochs,2)));
                  else % relative
                        nsel = length(selectedepochs);
                        evenindx = 2:2:nsel;
                        selectedepochs = selectedepochs(evenindx);
                  end
            elseif strcmpi(p.Results.Catching, 'prime')
                  %
                  % absolute or relative indexing?
                  %
                  if strcmpi(p.Results.Indexing, 'absolute')
                        selectedepochs = selectedepochs(isprime(selectedepochs));
                  else % relative
                        nsel = length(selectedepochs);
                        primeindx = primes(nsel); % prime relative (local) indices
                        selectedepochs = selectedepochs(primeindx);
                  end
            else
                  %onthefly --> default
            end
            
            %
            % EPISODE
            %
            pepisode = p.Results.Episode;
            nsegelem = length(pepisode);
            pepisode = reshape(reshape(pepisode,nsegelem/2,2), 2,nsegelem/2)'; % reorganize each couple as a row.
            npepi    = size(pepisode,1); % how many proportional episodes we got
            
            if isempty(pepisode)
                  part  = [];
                  total = [];
            else
                  total = 100;
                  part = [];
                  
                  for pe=1:npepi
                        part  = [part round(pepisode(pe,1)*100):round(pepisode(pe,2)*100)];
                  end
            end
            
            if ~isempty(part) && ~isempty(total)
                  if length(total)>1
                        error('prog:input', 'ERPLAB says: Specified total value must be a single value!.')
                  end
                  if max(part)>total
                        error('prog:input', 'ERPLAB says: Specified part value is larger than the specified total value!.')
                  end
                  
                  nevent   = length(ALLEEG(h).EVENTLIST.eventinfo); % total number of original events
                  segevent = round(nevent/total);
                  iteme    = [];
                  
                  for vv=1:length(part)
                        iteme = [iteme ((part(vv)-1)*segevent+1):((part(vv))*segevent)];
                  end
                  
                  okepoch = [];
                  g = 1;
                  
                  for t=1:length(selectedepochs)
                        xitem = cell2mat(ALLEEG(h).epoch(selectedepochs(t)).eventitem);
                        if nnz(ismember(xitem, iteme))>0
                              okepoch(g) = selectedepochs(t);
                              g = g + 1;
                        end
                  end
                  selectedepochs = okepoch;
            elseif (~isempty(part) && isempty(total)) || (isempty(part) && ~isempty(total))
                  error('ERPLAB says: Episode has a missing value')
            else
                  % keeps selectedepochs as it is
            end
            
            %
            % NUMBER OF EPOCHS PER BIN  (N FOR AVERAGING)
            %
            if ~isinf(nepoch(ibin))
                  if length(selectedepochs)<nepoch(ibin)
                        %disp('no alcanza')
                        if strcmpi(p.Results.Warning, 'on')
                              BackERPLABcolor = [1 0.9 0.3];    % yellow
                              question = ['There is not such amount of %s %s epochs in your dataset #%g, for bin #%g!\n\n'...
                                    'What would you like to do?'];
                              title = 'WARNING: criterion was not met';
                              oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                              set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                              button = questdlg(sprintf(question, p.Results.Catching, str4ep, setindxsetArray(h), binArray(ibin)), title,'Cancel','Continue','Continue');
                              set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                              fprintf(question, p.Results.Catching, str4ep, setindxsetArray(h), binArray(ibin));
                              
                              if ~strcmpi(button,'Continue')
                                    wannago = 0; % abort
                              end
                        end
                  else
                        % Instances
                        if strcmpi(p.Results.Instance, 'first')
                              selectedepochs = selectedepochs(1:nepoch(ibin));         % first instances
                        elseif strcmpi(p.Results.Instance, 'last')
                              selectedepochs = selectedepochs(end-nepoch(ibin)+1:end); % last instances
                        else
                              nsel = length(selectedepochs);
                              nselrindx = randperm(nsel);
                              selectedepochs = sort(selectedepochs(nselrindx(1:nepoch(ibin)))); %  random and sorted again...
                        end
                  end
            else
                  if strcmpi(p.Results.Instance, 'first') || strcmpi(p.Results.Instance, 'last')
                        BackERPLABcolor = [1 0.9 0.3];    % yellow
                        question = ['There is a problem with the input parameters.\n'...
                              'This is,\n'...
                              'If the "' p.Results.Instance '" instances are required the a finite amount of them must be specified.'];
                        title = 'WARNING: logical flaw';
                        oldcolor = get(0,'DefaultUicontrolBackgroundColor');
                        set(0,'DefaultUicontrolBackgroundColor',BackERPLABcolor)
                        button = questdlg(sprintf(question, p.Results.Catching, str4ep, setindxsetArray(h), binArray(ibin)), title,'Cancel','Continue','Continue');
                        set(0,'DefaultUicontrolBackgroundColor',oldcolor)
                        fprintf(question, p.Results.Catching, str4ep, setindxsetArray(h), binArray(ibin));
                        
                        if ~strcmpi(button,'Continue')
                              wannago = 0; % abort
                        end
                  end
            end
            if wannago==0
                  break % abort
            else
                  Tempeindices = [Tempeindices selectedepochs];
            end
      end
      % is everythig going well?
      if wannago==0 % no
            break
      else % yes
            Tempeindices = sort(Tempeindices);
            eindices{h}  = [eindices{h} Tempeindices];
      end
end
if wannago==0
      % abort
      eindices = [];
      return
end
