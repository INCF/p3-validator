function [signal,sample_mask] = flt_clean_windows(varargin)
% Remove periods of abnormal data from continuous data.
% [Signal,Mask] = flt_clean_windows(Signal,FlaggedQuantile,WindowLength,MaxIgnoredChannels,KeepMetadata)
%
% This is an autmated artifact rejection function which cuts segments of artifacts (characterized by
% their signal power) from the data.
%
% In:
%   Signal          : continuous data set, assumed to be appropriately high-passed (e.g. >0.5Hz or
%                     0.5Hz - 2.0Hz transition band)
%
%   FlaggedQuantile : upper quantile of the per-channel windows that should be flagged for potential
%                     removal (removed if flagged in all except for some possibly bad channels);
%                     controls the aggressiveness of the rejection; if two numbers are specified,
%                     the first is the lower quantile and the second is the upper quantile to be
%                     removed (default: 0.15)
%
%   WindowLength    : length of the windows (in seconds) which are inspected for artifact content;
%                     ideally as long as the expected time scale of the artifacts (e.g. chewing)
%                     (default: 1)
%
%   MinAffectedChannels : if for a time window more than this number (or ratio) of channels are
%                         affected (i.e. flagged), the window will be considered "bad". (default: 0.5)
%
%`  KeepMetadata    : boolean; whether meta data of EEG struct (such as events, ICA decomposition
%                     etc.) should be returned. If true, meta data is returned. Returning meta data
%                     is quite slow. (default: false)
%
% Out:
%   Signal : data set with bad time periods (and all events) removed, if keep_metadata is false.
%
%   Mask   : mask of retained samples (logical array)
%
% Examples:
%   % use the defaults
%   eeg = flt_clean_windows(eeg);
%
%   % use a more aggressive threshold and a custom window length
%   eeg = flt_clean_windows(eeg,0.25,0.5);
%
%   % use the default, but keep the meta-data (i.e. events, etc) - also, pass all parameters by name
%   eeg = flt_clean_windows('Signal',eeg,'KeepMetadata',true);
%
% See also:
%   flt_clean_channels, flt_clean_peaks
% 
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-07-06

if ~exp_beginfun('editing') return; end;

declare_properties('name','WindowCleaning', 'cannot_follow','set_makepos', 'follows','flt_iir', 'precedes','flt_fir', 'independent_channels',false, 'independent_trials',false);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'flag_quantile','FlaggedQuantile'}, 0.15, [0 1], 'Quantile of data windows flagged for removal. Windows are emoved if flagged in all except for some possibly bad channels, controls the aggressiveness of the rejection.'), ...
    arg({'window_len','WindowLength'}, 1, [], 'Window length to compute statistics. In seconds, ideally as long as the expected time scale of the artifacts (e.g., chewing).'), ...
    arg({'min_badchans','MinAffectedChannels'}, 0.5, [], 'Minimum affected channels. This is the minimum number of channels that need to be affected for the window to be considered "bad".'), ...
    arg({'keep_metadata','KeepMetadata'}, true, [], 'Retain metadata of EEG set. Retaining meta data (events, ICA decomposition, etc.) is quite slow.'), ...
    arg_nogui({'ignored_chans','MaxIgnoredChannels'}, [], [], 'Legacy parameter. Set this to emulate an old (not very meaningful) behavior.'));

if ~isempty(min_badchans) && min_badchans > 0 && min_badchans < 1 %#ok<*NODEF>
    min_badchans = size(signal.data,1)*min_badchans; end
if ~isempty(ignored_chans) && ignored_chans > 0 && ignored_chans < 1
    ignored_chans = size(signal.data,1)*ignored_chans; end
if ~isempty(min_badchans) && ~isempty(ignored_chans)
    error('You cannot use both the legacy and the current behavior at the same time.'); end
if isscalar(flag_quantile)
    flag_quantile = [0 flag_quantile]; end

[C,S] = size(signal.data);
window_len = window_len*signal.srate;
wnd = 0:window_len-1;
offsets = round(1:window_len/2:S-window_len);
W = length(offsets);

wpwr = zeros(C,W);
% for each channel
for c = 1:C
    % for each window
    for o=1:W
        % extract data
        x = signal.data(c,offsets(o) + wnd);
        % compute windowed power (measures both mean deviations, i.e. jumps, and large oscillations)
        wpwr(c,o) = sqrt(sum(x.^2)/window_len);
    end
end

[dummy,i] = sort(wpwr'); %#ok<TRSRT,ASGLU>

% find retained window indices per channel
retained_quantiles = i(1+floor(W*flag_quantile(1)):round(W*(1-flag_quantile(2))),:)';

% flag them in a Channels x Windows matrix (this can be neatly visualized)
retain_mask = zeros(C,W);
for c = 1:C
    retain_mask(c,retained_quantiles(c,:)) = 1; end

% find retained windows
if ~isempty(min_badchans)
    % new behavior
    retained_windows = find(sum(1-retain_mask) <= min_badchans);
else
    % legacy behavior
    retained_windows = find(sum(retain_mask) > ignored_chans);
end

% find retained samples
retained_samples = repmat(offsets(retained_windows)',1,length(wnd))+repmat(wnd,length(retained_windows),1);
% mask them out
sample_mask = false(1,S); sample_mask(retained_samples(:)) = true;
fprintf('Removing %.1f%% (%.0f seconds) of the data.\n',100*(1-mean(sample_mask)),nnz(~sample_mask)/signal.srate);
% visualize: figure;subplot(211);imagesc(retain_mask); subplot(212); plot(sum(1-retain_mask)/C); xlim([0 length(retain_mask)]); title(hlp_tostring(arg_nvps),'Interpreter','none');

if keep_metadata
    % retain the masked data, update meta-data appropriately
    retain_data_intervals = reshape(find(diff([false sample_mask false])),2,[])';
    retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;
    signal = pop_select(signal, 'point', retain_data_intervals);
    
    if isfield(signal.etc,'epoch_bounds') && isfield(signal.event,'target')
        targets = find(~cellfun('isempty',{signal.event.target}));
        retain = targets;
        % further restrict the set of retained events: generate epoch index range, in samples
        eporange = round(signal.etc.epoch_bounds(1)*signal.srate) : round(signal.etc.epoch_bounds(2)*signal.srate);
        
        if ~isempty(eporange)
            % prune events that exceed the data set boundaries
            lats = round([signal.event(retain).latency]);
            retain(lats+eporange(1)<1 | lats+eporange(end)>signal.pnts) = [];
            
            % generate a sparse mask of boundary events
            boundlats = min(signal.pnts,max(1,round([signal.event(strcmp({signal.event.type},'boundary')).latency])));
            if ~isempty(boundlats)
                boundmask = sparse(ones(1,length(boundlats)),boundlats,1,1,signal.pnts);
                
                % prune events that intersect the boundary mask
                lats = round([signal.event(retain).latency]);
                if ~isempty(lats)
                    retain(any(boundmask(bsxfun(@plus,eporange',lats)))) = []; end
                
                % now remove them
                remove = setdiff(targets,retain);
                signal.event(remove) = [];
            end
        end
    end
    
else
    % retain the masked data, clear all events or other aggregated data
    signal = exp_eval(set_new(signal,'data',signal.data(:,sample_mask),'icaact',[],'event',signal.event([]),'urevent',signal.urevent([]), ...
        'epoch',[],'reject',[],'stats',[],'specdata',[],'specicaact',[]));
end

exp_endfun;
