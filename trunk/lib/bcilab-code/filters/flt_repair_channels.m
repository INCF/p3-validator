function [signal,state] = flt_repair_channels(varargin)
% Repair (interpolate) broken channels online.
% Signal = flt_repair_channels(Signal,MinCorrelation,HistoryFraction,HistoryLength,WindowLength)
%
% This is an automated artifact rejection function which interpolates channels based on the others
% when they become decorrelated (e.g. loose). For large numbers of channels (128 or more) this function
% is computationally quite heavy as it computes the correlation between each channel and every other.
%
% In:
%   Signal          : continuous data set; note: this data set should be appropriately high-passed,
%                     e.g. using flt_iir.
%
%   MinimumCorrelation  : if a channel has less correlation than this value with any other channel
%                         in a time window, then it is considered "bad" during that window; a channel
%                         gets removed if it is bad for a sufficiently long time period (default: 0.6)
%
%   HistoryFraction : minimum fraction of time (in recent history) during which a channel must have
%                     been flagged as "bad" for it to be interpolated for a given time point.
%
%   HistoryLength   : length of channel "badness" history that HistoryFraction refers to, in seconds
%                     (default: 30)
%
%   WindowLength    : length of the windows (in seconds) for which channel "badness" is computed,
%                     i.e. time granularity of the measure; ideally short enough to reasonably
%                     capture periods of artifacts, but no shorter (otherwise the statistic becomes
%                     too noisy) (default: 1)
%
%   PreferICAoverPCA : Prefer ICA if available. If you have an ICA decomposition in your data, it 
%                      will be used and no PCA will be computed. If you don''t trust that ICA
%                      decomposition to be good enough set this to false (default: true)
%
%   PCACleanliness   : Rejetion quantile for PCA. If you don''t have a good ICA decomposition for
%                      your data, this is the quantile of data windows that are rejected/ignored
%                      before a PCA correlation matrix is estimated; the higher, the cleaner the PCA
%                      matrix will be (but the less data remains to estimate it). (default: 0.25)
%
%   PCAForgiveChannels : Ignored channel fraction for PCA. If you don''t have a good ICA decomposition 
%                        for your data, if you know that some of your channels are broken
%                        practically in the entire recording, this fraction would need to cover them
%                        (plus some slack). This is the fraction of broken channels that PCA will
%                        accept in the windows for which it computes correlations. The lower this
%                        is, the less data will remain to estimate the correlation matrix but more
%                        channels will be estimated properly. (default: 0.1)
%
%
% Out:
%   Signal : data set with bad channels removed
%
% Examples:
%   % use with defaults
%   eeg = flt_repair_channels(eeg);
%
%   % override the MinimumCorrelation default (making it more aggressive)
%   eeg = flt_clean_channels(eeg,0.7);
%
%   % override the MinimumCorrelation and the WindowLength, using name-value pairs
%   eeg = flt_clean_channels('Signal',eeg,'MinimumCorrelation',0.7, 'WindowLength',1.5);
%
% See also:
%   flt_clean_windows, flt_clean_peaks
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2012-01-10

if ~exp_beginfun('filter') return; end;

declare_properties('name','ChannelRepair', 'follows',{'flt_ica','flt_iir','flt_clean_windows','flt_clean_channels'}, 'precedes',{'flt_project','flt_fir'}, 'independent_channels',false, 'independent_trials',false);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg_norep({'state','State'}), ...
    arg({'min_corr','MinimumCorrelation'}, 0.6, [0 1], 'Minimum correlation between channels. This controls the aggressiveness of the filter: if the measure falls below this threshold for a channel in some time window, the window of that channel is considered bad.'), ...
    arg({'history_fraction','HistoryFraction'}, 0.5, [], 'History fraction. This is the minimum fraction of time (in recent history) during which a channel must have been flagged as "bad" for it to be interpolated for a given time point.'), ...
    arg({'history_len','HistoryLength'}, 0, [], 'History length. This is the length of the recent history of the channel for which channel "badness" is tracked, in seconds. This gives the filter some long-range stability -- however, for fast response to extremely high artifacts this should be very short (possibly even zero).'), ...
    arg({'window_len','WindowLength'}, 3, [], 'Window length to compute correlations. The length of the windows (in seconds) for which channel "badness" is computed, i.e. time granularity of the measure; ideally short enough to reasonably capture periods of artifacts, but no shorter (otherwise the statistic becomes too noisy).'),...
    arg({'prefer_ica','PreferICAoverPCA'}, true, [], 'Prefer ICA if available. If you have an ICA decomposition in your data, it will be used and no PCA will be computed. If you don'' trust your ICA decomposition to be good enough, uncheck this.'), ...
    arg({'pca_flagquant','PCACleanliness'}, 0.25, [], 'Rejetion quantile for PCA. If you don''t have a good ICA decomposition for your data, this is the quantile of data windows that are rejected/ignored before a PCA correlation matrix is estimated; the higher, the cleaner the PCA matrix will be (but the less data remains to estimate it).'), ...
    arg({'pca_maxchannels','PCAForgiveChannels'}, 0.1, [], 'Ignored channel fraction for PCA. If you don''t have a good ICA decomposition for your data, if you know that some of your channels are broken practically in the entire recording, this fraction would need to cover them (plus some slack). This is the fraction of broken channels that PCA will accept in the windows for which it computes correlations. The lower this is, the less data will remain to estimate the correlation matrix but more channels will be estimatedd properly.'));

mem_quota = 0.25; % maximum fraction of free memory that may be claimed by this function

% number of data points for our correlation window (N) and recent history (H)
N = window_len * signal.srate; %#ok<*NODEF>
H = history_len * signal.srate;

% first get rid of NaN's
signal.data(isnan(signal.data(:))) = 0;

% make up prior state if necessary
if ~exist('state','var') || isempty(state)
    if size(signal.data,2) < N+1
        error(['The data set needs to be longer than the statistics window length (for this data set ' num2str(window_len) ' seconds).']); end
    % mean, covariance filter conditions, history of "badness" per channel & sample, previously encountered breakage patterns & corresponding reconstruction matrices
    state = struct('ord1',[],'ord2',[],'bad',[],'offset',sum(signal.data,2)/size(signal.data,2),'patterns',[],'matrices',{{}});
    
    if isempty(signal.icawinv)|| ~prefer_ica
        % use a generic PCA decomposition
        disp('ChannelRepair: Using a PCA decomposition to interpolate channels; looking for clean data...');
        if isempty(utl_find_filter(signal,'flt_clean_windows'))
            % the signal has not yet been cleaned: do it now.
            tmp = exp_eval_optimized(flt_clean_windows('Signal',signal,'FlaggedQuantile',pca_flagquant,'MinAffectedChannels',pca_maxchannels));
        else
            % the signal is already cleaned: use it as-is
            tmp = signal;
        end
        disp('done; now repairing... (this may take a while)');
        sphere = 2.0*inv(sqrtm(double(cov(tmp.data')))); %#ok<MINV>
        state.winv = inv(sphere);
        state.chansind = 1:size(signal.data,1);
    else
        disp_once('ChannelRepair: Using the signal''s ICA decomposition to interpolate channels.');
        % use the ICA decomposition
        state.winv = signal.icawinv;
        state.chansind = signal.icachansind;
    end
    % prepend a made-up data sequence
    signal.data = [repmat(2*signal.data(:,1),1,N) - signal.data(:,(N+1):-1:2) signal.data];
    prepended = true;
else
    prepended = false;
end

% split up the total sample range into k chunks that will fit in memory
[C,S] = size(signal.data);
E = eye(C)~=0;
if S > 1000
    numsplits = ceil((C^2*S*8*5) / (hlp_memfree*mem_quota));
else
    numsplits = 1;
end
for i=0:numsplits-1
    range = 1+floor(i*S/numsplits) : min(S,floor((i+1)*S/numsplits));
    % get raw data X (-> note: we generally restrict ourselves to channels covered by the decomposition)
    X = double(bsxfun(@minus,signal.data(state.chansind,range),state.offset(state.chansind)));
    % ... and running mean E[X]
    [X_mean,state.ord1] = moving_average(N,X,state.ord1,2);
    % get unfolded cross-terms tensor X*X'
    [m,n] = size(X); X2 = reshape(bsxfun(@times,reshape(X,1,m,n),reshape(X,m,1,n)),m*m,n);
    % ... and running mean of that E[X*X']
    [X2_mean,state.ord2] = moving_average(N,X2,state.ord2,2);
    % compute running covariance E[X*X'] - E[X]*E[X]'
    X_cov = X2_mean - reshape(bsxfun(@times,reshape(X_mean,1,m,n),reshape(X_mean,m,1,n)),m*m,n);
    % get running std dev terms
    X_std = sqrt(X_cov(E,:));
    % clear the diagonal covariance terms
    X_cov(E,:) = 0;
    % cross-multiply std dev terms
    X_crossvar = bsxfun(@times,reshape(X_std,1,m,n),reshape(X_std,m,1,n));
    % normalize the covariance by it (turning it into a running correlation)
    X_corr = X_cov ./ reshape(X_crossvar,m*m,n);
    
    % calculate the per-sample maximum correlation
    X_maxcorr = reshape(max(reshape(X_corr,m,m,n)),m,n);
    % calculate the per-sample 'badness' criterion
    X_bad = X_maxcorr < min_corr;
    
    % filter this using a longer moving average to get the fraction-of-time-bad property
    if history_len > 0
        [X_fracbad,state.bad] = moving_average(H,X_bad,state.bad,2);
        % get the matrix of channels that need to be filled in
        X_fillin = X_fracbad > history_fraction;
    else
        X_fillin = X_bad;
    end
    
    % create a mask of samples that need handling
    X_pattern = sum(X_fillin);
    X_mask = X_pattern>0;
    % get the unique breakage patterns in X_fillin
    [patterns,dummy,occurrence] = unique(X_fillin(:,X_mask)','rows'); %#ok<ASGLU>
    % and the occurrence mask
    X_pattern(X_mask) = occurrence;
    
    % for each pattern...
    for p=1:size(patterns,1)
        patt = patterns(p,:);
        % does it match any known pattern in our state?
        try
            match = all(bsxfun(@eq,patt,state.patterns)');
            reconstruct = state.matrices{match};
        catch
            % no: generate the corresponding reconstruction matrix first
            M_train = state.winv;
            M_trunc = M_train(~patt,:);
            U_trunc = pinv(M_trunc);
            reconstruct = M_train*U_trunc;
            reconstruct = reconstruct(patt,:);
            % append it to the state's DB
            state.patterns = [state.patterns; patt];
            state.matrices{size(state.patterns,1)} = reconstruct;
        end
        % now reconstruct the corresponding broken channels
        mask = p==X_pattern;
        signal.data(state.chansind(patt),range(mask)) = reconstruct * signal.data(state.chansind(~patt),range(mask));
    end
end

% trim the prepended part if there was one
if prepended
    signal.data(:,1:N) = []; end

exp_endfun;
