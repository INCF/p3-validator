function signal = flt_clean_channels(varargin)
% Remove channels with abnormal data from a continuous data set.
% Signal = flt_clean_channels(Signal,MinCorrelation,IgnoredQuantile,WindowLength,MaxIgnoredTime,Rereferenced)
%
% This is an automated artifact rejection function which ensures that the data set contains no
% channels that record complete trash. If channels with control signals are contained in the data,
% these are usually also removed.
%
% In:
%   Signal          : continuous data set, assumed to be appropriately high-passed (e.g. >0.5Hz or
%                     with a 0.5Hz - 2.0Hz transition band)
%
%   MinimumCorrelation  : if a channel has less correlation than this value with any other channel
%                         in a time window, then it is considered "bad" during that window; a channel
%                         gets removed if it is bad for a sufficiently long time period (default: 0.6)
%
%   IgnoredQuantile : upper quantile in the correlation measure that is always ignored; 
%                     this allows extremely correlated (e.g. shorted) channels to be removed
%                     (default: 0.1)
%
%   WindowLength    : length of the windows (in seconds) for which channel "badness" is computed, 
%                     i.e. time granularity of the measure; ideally short enough to reasonably
%                     capture periods of multi-channel artifacts (which are ignored), but no shorter
%                     (for computational reasons) (default: 1)
% 
%   MaxIgnoredTime  : if a channel is bad for more than this time (in seconds, or as a fraction of
%                     the data set), it will be removed (default: 0.4)
%
%   Rereferenced    : whether the measures should be computed on re-referenced data (default: false)
%
% Out:
%   Signal : data set with bad channels removed
%
% Examples:
%   % use with defaults
%   eeg = flt_clean_channels(eeg);
%
%   % override the MinimumCorrelation and the IgnoredQuantile defaults
%   eeg = flt_clean_channels(eeg,0.7,0.15);
%
%   % override the MinimumCorrelation and the MaxIgnoredTime, using name-value pairs
%   eeg = flt_clean_channels('Signal',eeg,'MinimumCorrelation',0.7, 'MaxIgnoredTime',0.15);
%
%   % override the MinimumCorrelation and the MaxIgnoredTime, using name-value pairs 
%   % in their short forms
%   eeg = flt_clean_channels('signal',eeg,'min_corr',0.7, 'ignored_time',0.15);
%
% See also:
%   flt_clean_windows, flt_clean_peaks
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-07-06

if ~exp_beginfun('filter') return; end;

declare_properties('name','ChannelCleaning', 'cannot_follow','set_makepos', 'follows',{'flt_iir','flt_clean_windows'}, 'precedes','flt_fir', 'independent_channels',false, 'independent_trials',false);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'min_corr','MinimumCorrelation'}, 0.6, [0 1], 'Minimum correlation between channels. If the measure falls below this threshold in some time window, the window is considered abnormal.'), ...
    arg({'ignored_quantile','IgnoredQuantile'}, 0.1, [0 1], 'Quantile of highest correlations ignored. Upper quantile of the correlation values that may be arbitrarily high without affecting the outcome - avoids problems with shorted channels.'), ...
    arg({'window_len','WindowLength'}, 1, [], 'Window length to compute correlations. In seconds, ideally short enough to reasonably capture periods of global artifacts (which are ignored), but no shorter, to keep statistics healthy.'), ...
    arg({'ignored_time','MaxIgnoredTime'}, 0.4, [], 'Maximum time or fraction of data to ignore. Maximum time (in seconds or as ratio) in the data set, that may contain arbitrary data without affecting the outcome.'), ...
    arg({'rereferenced','Rereferenced'},false,[],'Run calculations on re-referenced data.'), ...
    arg_norep('removed_channels',unassigned)); 

% flag channels
if ~exist('removed_channels','var')
    if ignored_time > 0 && ignored_time < 1  %#ok<*NODEF>
        ignored_time = size(signal.data,2)*ignored_time;
    else
        ignored_time = signal.srate*ignored_time;
    end
    
    [C,S] = size(signal.data);
    window_len = window_len*signal.srate;
    wnd = 0:window_len-1;
    offsets = round(1:window_len:S-window_len);
    W = length(offsets);    
    retained = 1:(C-ceil(C*ignored_quantile));

    % optionally subtract common reference from data
    if rereferenced
        X = signal.data - repmat(mean(signal.data),C,1);
    else
        X = signal.data;
    end
    
    flagged = zeros(C,W);
    % for each window, flag channels with too low correlation to any other channel (outside the
    % ignored quantile)
    for o=1:W
        sortcc = sort(abs(corrcoef(X(:,offsets(o)+wnd)')));
        flagged(:,o) = all(sortcc(retained,:) < min_corr);
    end
    % mark all channels for removal which have more flagged samples than the maximum number of
    % ignored samples
    removed_channels = find(sum(flagged,2)*window_len > ignored_time);
end

% execute
signal = pop_select(signal,'nochannel',removed_channels);

exp_endfun('append_online',{'removed_channels',removed_channels});
