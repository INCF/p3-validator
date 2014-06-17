function eeg = set_new(varargin)
% Create a new EEGLAB data set from individual fields.
% Dataset = set_new(Arguments...)
%
% In:
%   Fields  : Pairs of field names and field values to add to the data set. fields not specified are
%             taken from eeg_emptyset, later fields override earlier fields; giving a struct in
%             place of a name-value pair is equivalent to writing out all the struct fieldnames and
%             respective values. fields that can be derived from others are derived.
%
%   `         optional special semantics:
%             * 'chanlocs' can be specified as cell-string array, and is generally completed using a 
%                default lookup
%             * 'data' can be specified as a cell array of data arrays, then concatenated across 
%                epochs, and with .epoch.target derived as the index of the cell which contained the 
%                epoch in question.
%             * 'tracking.online_expression' can be specified to override the online processing 
%                description
%
% Out:
%   Dataset : newly created EEGLAB set
% 
% Example:
%   % create a new continuous data set (with channels A, B, and C, and 1000 Hz sampling rate)
%   myset = set_new('data',randn(3,100000), 'srate',1000,'chanlocs',struct('labels',{'A','B','C'}));
%
%   % as before, but now also put in some events at certain latencies (note: latencies are in samples)
%   events = struct('type',{'X','Y','X','X','Y'},'latency',{1000,2300,5000,15000,17000});
%   myset = set_new('data',randn(3,100000), 'srate',1000, 'chanlocs',struct('labels',{'A','B','C'}), 'event',events);
%
% See also:
%   eeg_emptyset
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-05-28

if ~exp_beginfun('filter') return; end

declare_properties('independent_channels',false,'independent_trials',false);

% construct the data set from arguments and defaults
eeg = hlp_varargin2struct(varargin, eeg_emptyset, 'setname','new set');

% rewrite cell array data
if iscell(eeg.data)
    data = eeg.data;
    eeg.data = [];
    for c=1:length(data)
        if isnumeric(data{c}) && ~isempty(data{c})
            eeg.data = cat(3, eeg.data, data{c});
            for i=size(eeg.data,3)-size(data{c},3)+1:size(eeg.data,3)
                eeg.epoch(i).target = c; end
        end
    end    
end

% bring chanlocs into an appropriate format
try  eeg.chanlocs = hlp_microcache('setnew',@set_infer_chanlocs,eeg.chanlocs); catch end

% if necessary, create chanlocs from scratch, according to the data size
if ~isfield(eeg,'chanlocs') || isempty(eeg.chanlocs)
    if ~isempty(eeg.data)
        eeg.chanlocs = struct('labels',cellfun(@num2str,num2cell(1:size(eeg.data,1),1),'UniformOutput',false),'type',repmat({'unknown'},1,size(eeg.data,1))); 
    else
        eeg.chanlocs = struct('labels',{},'type',{});
    end
end


% derive xmax, nbchan, pnts, trials
[eeg.nbchan,eeg.pnts, eeg.trials] = size(eeg.data);
eeg.xmax = eeg.xmin + (eeg.pnts-1)/eeg.srate;

% derive additional event & urevent info
if isfield(eeg,'event')
    eeg = eeg_checkset(eeg,'eventconsistency'); 
    eeg = eeg_checkset(eeg,'makeur'); 
end

% add epoch.latency if possible
if ~isfield(eeg.epoch,'latency')
    for i=1:length(eeg.epoch)
        try
        tle = [eeg.epoch(i).eventlatency{:}]==0;
        if any(tle)
            eeg.epoch(i).latency = b.event(b.epoch(i).event(tle)).latency; end
        catch
        end
    end
end

% do minimal consistency checks
if ~isempty(eeg.chanlocs) && ~isempty(eeg.data) && (length(eeg.chanlocs) ~= eeg.nbchan)
    if length(eeg.chanlocs) == eeg.nbchan+1 
        if isfield(eeg,'ref') && isscalar(eeg.ref) && eeg.ref <= eeg.nbchan
            eeg.chanlocs = eeg.chanlocs(setdiff(1:eeg.nbchan,eeg.ref));
        elseif any(strcmpi({eeg.chanlocs.labels},'ref'))
            eeg.chanlocs = eeg.chanlocs(~strcmpi({eeg.chanlocs.labels},'ref'));
        else
            error('The number of supplied channel locations does not match the number of channels in the data. Apparently includes 1 special channel...'); 
        end
    else
        error('The number of supplied channel locations does not match the number of channels in the data.'); 
    end
end
if isfield(eeg,'epoch') && ~isempty(eeg.epoch) && length(eeg.epoch) ~= size(eeg.data,3)
    error('The number of data epochs does not match the number of entries in the epoch field'); end

if isfield(eeg,'tracking') && isfield(eeg.tracking,'online_expression')
    % if an online expression was explicitly assigned in set_new, use that
    exp_endfun('set_online',eeg.tracking.online_expression);
else
    % otherwise, we treat this as raw data
    exp_endfun('set_online',struct('head',@rawdata,'parts',{{{eeg.chanlocs.labels},unique({eeg.chanlocs.type})}}));
end
