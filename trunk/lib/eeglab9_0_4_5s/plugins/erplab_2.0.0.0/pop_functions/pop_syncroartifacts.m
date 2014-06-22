% EEG = pop_syncroartifacts(EEG, direction);
%
%     direction = 1; % erplab to eeglab synchro
%     direction = 2; %eeglab to erplab synchro
%     direction = 3; % both
%     direction = 0; % none
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

function [EEG com]= pop_syncroartifacts(EEG,direction)

com = '';
if isempty(EEG)
        msgboxText =  'pop_syncroartifacts cannot work with an empty dataset!';
        title = 'ERPLAB: pop_syncroartifacts(), permission denied';
        errorfound(msgboxText, title);
        return
end
if length(EEG)>1
        msgboxText =  'Unfortunately, this function does not work with multiple datasets';
        title = 'ERPLAB: multiple inputs';
        errorfound(msgboxText, title);
        return
end
if isempty(EEG.epoch)
        msgboxText =  'pop_syncroartifacts has been tested for epoched data only';
        title = 'ERPLAB: pop_syncroartifacts(), permission denied';
        errorfound(msgboxText, title);
        return
end
if isfield(EEG, 'EVENTLIST')
        if isfield(EEG.EVENTLIST, 'eventinfo')
                if isempty(EEG.EVENTLIST.eventinfo)
                        msgboxText = ['EVENTLIST.eventinfo structure is empty!\n'...
                                'pop_syncroartifacts() will not be performed.'];
                        title = 'ERPLAB: pop_syncroartifacts() error';
                        errorfound(sprintf(msgboxText), title);
                        return
                end
        else
                msgboxText =  ['EVENTLIST.eventinfo structure was not found!\n'...
                        'pop_syncroartifacts() will not be performed.'];
                title = 'ERPLAB: pop_syncroartifacts() error';
                errorfound(sprintf(msgboxText), title);
                return
        end
else
        msgboxText =  ['EVENTLIST structure was not found!\n'...
                'pop_syncroartifacts() will not be performed.'];
        title = 'ERPLAB: pop_syncroartifacts() error';
        errorfound(sprintf(msgboxText), title);
        return
end
if nargin==1
        direction = synchroartifactsGUI;
        %     direction = 1; % erplab to eeglab synchro
        %     direction = 2; % eeglab to erplab synchro
        %     direction = 3; % both
        %     direction = 0; % none
        if isempty(direction)
                disp('User selected Cancel')
                return
        end
else
        if nargin>2
                error('ERPLAB says: Too many inputs!')
        end
        if direction<0 || direction>3
                error('ERPLAB says: direction can only be 0, 1, 2, or 3')
        end
end
if direction==0
        fprintf('User decided not to synchronize.\n');
        return
end

%
% Tests RT info
%
isRT = 1; % there is RT info by default
if ~isfield(EEG.EVENTLIST.bdf, 'rt')
        isRT = 0; % no RT info
else
        valid_rt = nnz(~cellfun(@isempty,{EEG.EVENTLIST.bdf.rt}));
        if valid_rt==0
                isRT = 0; % no RT info
        end
end

%
% Synchronization
%
if direction==1      % erplab to eeglab synchro
        EEG = synchroner1(EEG);
elseif direction==2  %eeglab to erplab synchro
        EEG = synchroner2(EEG, isRT);
elseif direction==3 % both
        EEG = synchroner1(EEG);
        EEG = synchroner2(EEG, isRT);
end

com = sprintf( '%s = pop_syncroartifacts(%s, %s);', inputname(1), inputname(1), num2str(direction));
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return

% ---------------------------------------------------------------------------
function EEG = synchroner1(EEG)

%
% erplab to eeglab synchro by info at EEG.epoch.eventflag
%
fprintf('\n---------------------------------------------------------\n');
fprintf('STEP 1: Synchronizing EEG.reject.rejmanual by EEG.epoch.eventflag...\n');
fprintf('---------------------------------------------------------\n\n');
nepoch = EEG.trials;
for i=1:nepoch
        cflag = EEG.epoch(i).eventflag; % flag(s) from event(s) within this epoch
        if iscell(cflag)
                cflag = cell2mat(cflag);
        end
        laten = EEG.epoch(i).eventlatency;% latency(ies) from event(s) within this epoch
        if iscell(laten)
                laten = cell2mat(laten);
        end

        indxtimelock = find(laten == 0,1,'first'); % catch zero-time locked code position,
        flag  = cflag(indxtimelock);

        if flag>0
                EEG.reject.rejmanual(i) = 1; % marks epoch with artifact
                %EEG.reject.rejmanualE(chanArray(ch), i) = 1; % marks channel with artifact
                iflag = find(bitget(flag,1:8));
                fprintf('Epoch # %g was marked due to flag(s) # %s was(were) set for its home item.\n',i, num2str(iflag));
        else
                if EEG.reject.rejmanual(i)==1
                        EEG.reject.rejmanual(i)=0;
                        fprintf('The mark at epoch # %g was removed due to no set flag was found at its home item.\n',i);
                end
        end
end

%
% erplab to eeglab synchro by info at EEG.EVENTLIST.eventinfo.flag and EEG.EVENTLIST.eventinfo.bepoch
%
fprintf('\n---------------------------------------------------------\n');
fprintf('STEP 2: Synchronizing EEG.reject.rejmanual by EEG.EVENTLIST.eventinfo.flag and EEG.EVENTLIST.eventinfo.bepoch...\n');
fprintf('---------------------------------------------------------\n\n');
nitem = length(EEG.EVENTLIST.eventinfo);
for i=1:nitem
        flag   = EEG.EVENTLIST.eventinfo(i).flag;
        bepoch = EEG.EVENTLIST.eventinfo(i).bepoch;
        if bepoch>0
                if flag>0
                        EEG.reject.rejmanual(bepoch) = 1; % marks epoch with artifact
                        iflag = find(bitget(flag,1:8));
                        fprintf('Epoch # %g was marked due to flag(s) # %s was(were) set for item # %g.\n',bepoch, num2str(iflag), i);
                else
                        if EEG.reject.rejmanual(bepoch)==1
                                EEG.reject.rejmanual(bepoch)=0;
                                fprintf('The mark at epoch # %g was removed due to no set flag was found at item # %g.\n', bepoch, i);
                        end
                end
        end
end
fprintf('\nEEG.reject.rejmanual(i) was synchronized according to EEG.epoch(i).eventflag values.\n')
return

% ---------------------------------------------------------------------------
function EEG = synchroner2(EEG, isRT)
%eeglab to erplab synchro

ntrial = EEG.trials;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'rejjp' 'rejkurt' 'rejmanual' 'rejthresh' 'rejconst' 'rejfreq'...
% 'icarejjp' 'icarejkurt' 'icarejmanual' 'icarejthresh' 'icarejconst'...
% 'icarejfreq' 'rejglobal'
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F = fieldnames(EEG.reject);
sfields1 = regexpi(F, '\w*E$', 'match');
sfields2 = [sfields1{:}];
arfields  = regexprep(sfields2,'E',''); % EEGLAB's artifact rejection fields

indx = [];
for i=1:length(arfields)
        if ~isempty(EEG.reject.(arfields{i}))
                indx = [indx i];
        end
end

fprintf('\n---------------------------------------------------------\n');
fprintf('Synchronizing EEG.EVENTLIST.eventinfo and EEG.epoch by EEG.reject.{ar_tool}...\n');
fprintf('---------------------------------------------------------\n\n');

selarfields = arfields(indx); % not empty EEGLAB's artifact rejection fields
nsarf = length(selarfields);
for i=1:ntrial;
        r = zeros(1,nsarf);
        for j=1:nsarf
                r(j) = EEG.reject.(selarfields{j})(i);
        end
        if nnz(r)>0
                EEG = markartifacts(EEG, 1, [], [], i, isRT, 1);
        end
end

fprintf('\nFlag 1 was marked at EEG.EVENTLIST.eventinfo and EEG.epoch, according to EEG.reject.{ar_tool}.\n');

if isRT
        fprintf('For reaction time filtering, EEG.EVENTLIST.bdf was synchronized with artifact detection info as well.\n\n');
else
        fprintf('EEG.EVENTLIST.bdf was not synchronized due to reaction time measurement was not found in this dataset.\n\n');
end
return
