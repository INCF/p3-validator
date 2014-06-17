function signal = flt_clean_peaks(varargin)
% Project local peaks out of the data (blinks, muscle artifacts, brief jumps). Non-causal.
% Signal = flt_clean_peaks(Signal,RemovedQuantile,WindowLength)
%
% This is an automated artifact rejection function that ensures that the data contains no events
% that have abnormally strong power; these events are projected out of the data, i.e. no time
% periods are cut. The function should only be used as an optional final clean-up step, after bad
% channels (using flt_clean_channels) and largely trashed time windows (using flt_clean_windows)
% have been removed, usually to get a good decomposition into independent brain components (via
% flt_ica). Doing machine learning directly on the cleaned data can give results which look clean,
% but which may depend on the fact that data was projected out whenever muscle artifacts (etc.)
% appeared.
%
% In:
%   Signal          : continuous data set, assumed to be appropriately high-passed (e.g. >0.5Hz or
%                     with a 0.5Hz - 2.0Hz transition band)
%
%   RemovedQuantile : upper quantile of the signal that should be flagged as "bad"; controls the
%                     aggressiveness of the filter (default: 0.2)
%
%   WindowLength    : length of the windows (in seconds) for which the power is computed, i.e. the 
%                     granularity of the measure; ideally short enough to reasonably isolate
%                     artifacts, but no shorter (for computational reasons) (default: 0.5)
%
% Out:
%   Signal : data set with local peaks removed
%
% Examples:
%   % use the defaults
%   eeg = flt_clean_peaks(eeg);
%
%   % use a more aggressive threshold and different window length
%   eeg = flt_clean_peaks(eeg,0.3,0.75);
%
%   % use a different window length, and pass parameters by name
%   eeg = flt_clean_peaks('signal',eeg,'WindowLength',0.75);
%
% See also:
%   flt_clean_channels, flt_clean_windows
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-07-10

if ~exp_beginfun('editing') return; end

declare_properties('name','BurstCleaning', 'cannot_follow','set_makepos', 'follows',{'flt_iir','flt_clean_channels'}, 'precedes','flt_fir', 'independent_channels',false, 'independent_trials',false);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'remove_quantile','RemovedQuantile'}, 0.2, [0 1], 'Upper quantile of the data that should be removed. Controls the aggressiveness of the filter.'), ...
    arg({'window_len','WindowLength'}, 0.5, [], 'Window length to compute signal power. In seconds, ideally short enough to reasonably isolate artifacts, but no shorter, to keep statistics healthy.'));

% get data properties
[C,S] = size(signal.data); %#ok<*NODEF>
window_len = window_len*signal.srate;
wnd = 0:window_len-1;
wnd_weight = repmat(0.5*hann(length(wnd))',C,1);
offsets = 1 + floor(0:window_len/4:S-window_len);
W = length(offsets);

% find the covariance distribution of the data (across windows)
X = signal.data;
XC = zeros(C,C,length(offsets));
for o=1:W
    S = X(:,offsets(o) + wnd).*wnd_weight;
    XC(:,:,o) = cov(S');
end
% and find the selected quantile of that
XX = sort(XC,3);
XQ = XX(:,:,floor(length(offsets)*(1-remove_quantile)));

Y = zeros(C,size(signal.data,2));
for o=1:W
    % get the data window and its principal components (basis for the new signal)
    S = X(:,offsets(o) + wnd) .* wnd_weight;
    [V,D] = eig(cov(S'));
    % mask out components that are extremal (considering only the larger half of components)
    mask = diag(D) < diag(V'*XQ*V); mask(1:ceil(length(mask)/2)) = 1;
    M = V * diag(mask) * V';
    % and project them out of the data
    Y(:,offsets(o) + wnd) = Y(:,offsets(o) + wnd) + M*S;
end

% write back
signal.data = Y;
signal.nbchan = size(signal.data,1);

exp_endfun;
