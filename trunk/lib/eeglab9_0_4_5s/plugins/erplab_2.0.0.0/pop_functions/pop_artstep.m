% Usage
%
% >> EEG = erp_artmwppth(EEG, twin, ampth, winms, stepms, chan, flag);
%
% Inputs
%
% EEG       - input dataset
% twin      - time period in ms to apply this tool (start end). Example [-200 800]
% ampth     - difference threshold between the average of the first half moving window
%             and the average of the second half (in uV).
% winms     - moving window width in ms.
% stepms    - moving window step in ms.
% chan      - channel(s) to search artifacts.
% flag      - flag value between 1 to 8 to be marked when an artifact is found. (1 value)
%
% Output
%
% EEG       - output dataset
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

function [EEG com] = pop_artstep(EEG, twin, ampth, winms, stepms, chan, flag)

com = '';

if nargin<1
        help pop_artstep
        return
end
if length(EEG)>1
      msgboxText =  'Unfortunately, this function does not work with multiple datasets';
      title = 'ERPLAB: multiple inputs';
      errorfound(msgboxText, title);
      return
end
if isempty(EEG.data)
        msgboxText =  'pop_artstep() cannot read an empty dataset!';
        title = 'ERPLAB: pop_artstep error';
        errorfound(msgboxText, title);
        return
end
if isempty(EEG.epoch)
        msgboxText =  'pop_artstep has been tested for epoched data only';
        title = 'ERPLAB: pop_artstep() permission denied';
        errorfound(msgboxText, title);
        return
end
if isfield(EEG, 'EVENTLIST')
    if isfield(EEG.EVENTLIST, 'eventinfo')
        if isempty(EEG.EVENTLIST.eventinfo)
            msgboxText = ['EVENTLIST.eventinfo structure is empty!\n'...
                'You will not be able to perform ERPLAB''s\n'...
                'artifact detection tools.'];
            title = 'ERPLAB: Error';
            errorfound(sprintf(msgboxText), title);
            return
        end
    else
        msgboxText =  ['EVENTLIST.eventinfo structure was not found!\n'...
            'You will not be able to perform ERPLAB''s\n'...
            'artifact detection tools.'];
        title = 'ERPLAB: Error';
        errorfound(sprintf(msgboxText), title);
        return
    end
else
    msgboxText =  ['EVENTLIST structure was not found!\n'...
        'You will not be able to perform ERPLAB''s\n'...
        'artifact detection tools.'];
    title = 'ERPLAB: Error';
    errorfound(sprintf(msgboxText), title);
    return
end

%
% Gui is working...
%
nvar = 7;
if nargin <nvar

        prompt = {'Test period (start end) [ms]', 'Voltage Threshold [uV]', 'Moving Windows Full Width [ms]',...
                'Window Step (ms)','Channel(s)'};
        dlg_title = 'Step Function';
        defx = {[EEG.xmin*1000 EEG.xmax*1000] 100 200 50 [1:EEG.nbchan] 0};
        def = erpworkingmemory('pop_artstep');

        if isempty(def)
                def = defx;
        else
                if def{1}(1)<EEG.xmin*1000
                        def{1}(1) = single(EEG.xmin*1000);
                end
                if def{1}(2)>EEG.xmax*1000
                        def{1}(2) = single(EEG.xmax*1000);
                end

                def{5} = def{5}(ismember(def{5},1:EEG.nbchan));
        end

        answer = artifactmenuGUI(prompt, dlg_title, def, defx);

        if isempty(answer)
                disp('User selected Cancel')
                return
        end

        testwindow =  answer{1};
        ampth      =  answer{2};
        winms      =  answer{3};
        stepms     =  answer{4};
        chanArray  =  unique(answer{5}); % avoids repeted channels
        flag       =  answer{6};

        if ~isempty(find(flag<1 | flag>16, 1))
                msgboxText{1} =  'ERROR, flag cannot be greater than 16 nor lesser than 1';
                title = 'ERPLAB: Flag input';
                errorfound(msgboxText, title);
                return
        end

        erpworkingmemory('pop_artstep', {answer{1} answer{2} answer{3} answer{4} answer{5} answer{6}});

elseif nargin==nvar
        testwindow =  twin;
        chanArray = chan;

        if ~isempty(find(flag<1 | flag>16, 1))
                error('ERPLAB says: error at pop_artabsth(). Flag cannot be greater than 16 or lesser than 1')
        end
else
        error('ERPLAB says: pop_artstep() works with 7 arguments')
end

if length(ampth)>1
        error('ERPLAB says: you must enter 1 value for peak-to-peak Voltage threshold')
end

chArraystr = vect2colon(chanArray);

fs       = EEG.srate;
nch      = length(chanArray);
ntrial   = EEG.trials;
winpnts  = floor(winms*fs/1000);
stepnts  = floor(stepms*fs/1000);

if stepnts<1
        error('ERPLAB says: The minimun step value should be equal to the sampling period (1/fs msec).')
end

[p1 p2 checkw] = window2sample(EEG, testwindow, fs);

if checkw==1
        error('pop_artstep() error: time window cannot be larger than epoch.')
elseif checkw==2
        error('pop_artstep() error: too narrow time window')
end

epochwidth = p2-p1+1; % choosen epoch width in number of samples

if nch>EEG.nbchan
        error('ERPLAB says: pop_artstep() number of tested channels cannot be greater than total.')
end

if winpnts>epochwidth
        error('pop_artstep() error: time window cannot be larger than epoch')
elseif winpnts<2
        error('pop_artstep() error: too narrow time window')
end

if isempty(EEG.reject.rejmanual)
        EEG.reject.rejmanual  = zeros(1,ntrial);
        EEG.reject.rejmanualE = zeros(EEG.nbchan, ntrial);
end

interARcounter = zeros(1,ntrial); % internal counter, for statistics

fprintf('channel #\n ');

%
% Tests RT info
%
isRT = 1; % there is RT info by default
if ~isfield(EEG.EVENTLIST.bdf, 'rt')
        isRT = 0;
else
        valid_rt = nnz(~cellfun(@isempty,{EEG.EVENTLIST.bdf.rt}));
        if valid_rt==0
                isRT = 0;
        end
end
for ch=1:nch
        fprintf('%g ',chanArray(ch));
        for i=1:ntrial;
                for j=p1:stepnts:p2-(winpnts-1)

                        w1  = EEG.data(chanArray(ch), j:j+round(winpnts/2)-1,i);
                        w2  = EEG.data(chanArray(ch), j+round(winpnts/2):j+winpnts-1 ,i);
                        vs = abs(mean(w1)-mean(w2));

                        if vs>ampth

                                interARcounter(i) = 1;      % internal counter, for statistics
                                % flaf 1 is obligatory
                                [EEG errorm]= markartifacts(EEG, flag, chanArray, ch, i, isRT);
                                if errorm==1
                                        error(['ERPLAB says: There was not latency at the epoch ' num2str(i)])
                                elseif errorm==2
                                        error('ERPLAB says: invalid flag (0<=flag<=16)')
                                end
                                break
                        end
                end
        end
end

% Update EEG.EVENTLIST.bdf structure ( for RTs)
% EEG = updatebdfstruct(EEG);

fprintf('\n');

% performance
perreject = nnz(interARcounter)/ntrial*100;
fprintf('pop_artstep() rejected a %.1f %% of total trials.\n', perreject);

EEG.setname = [EEG.setname '_ar'];
EEG = eeg_checkset( EEG );

if ~ischar(testwindow)
        testwindow = ['[' num2str(testwindow) ']'];
end
namefig = 'Step-like artifacts view';
if nargin <nvar
        pop_plotepoch4erp(EEG, namefig)
end

flagstr = vect2colon(flag);

com = sprintf( '%s = pop_artstep( %s, %s, %s, %s, %s, %s, %s);', ...
        inputname(1), inputname(1), testwindow, num2str(ampth), num2str(winms),...
        num2str(stepms), chArraystr, flagstr);

try cprintf([0 0 1], 'COMPLETE\n\n');catch fprintf('COMPLETE\n\n');end ;
return