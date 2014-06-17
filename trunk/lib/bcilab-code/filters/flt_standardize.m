function [signal,state] = flt_standardize(varargin)
% Standardize a continuous EEG set causally.
% [Signal,State] = flt_standardize(Signal, State, WindowLength)
%
% Standardization ensures that per-channel data that normally can have any variance (e.g. due to
% varying conductivity, amplifier settings, etc.) is approximately normally distributed over data
% sets and time periods. This is usually necessary when learning and running models across sessions
% and subjects. It should not be applied before other artifact-rejection steps, as these steps
% usually take relative signal power into account. It is important to make the standardization
% window long enough that it does not factor out changes in signal power that one is interested in.
%
% In:
%   Signal       :   continuous data set to be filtered
%
%   WindowLength :   length of the window based on which normalization shall be performed, in
%                    seconds (default: 30)
%
%   State        :   previous filter state, as obtained by a previous execution of flt_iir on an
%                    immediately preceding data set (default: [])
%
% Out: 
%   Signal       :  standardized, continuous data set
%
%   State        :  state of the filter, after it got applied
%
% Examples:
%   % standardize the data in a moving window of default length (30s)
%   eeg = flt_standardize(eeg)
%
%   % standardize the data in a moving window of 60s length
%   eeg = flt_standardize(eeg,60)
%
%   % as previous, but passing all parameters by name
%   eeg = flt_standardize('Signal',eeg,'WindowLength',60)
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-17

if ~exp_beginfun('filter') return; end

% follows IIR/FIR, as it should operate on a clean signal (rather than depend on HF noise, etc.)
declare_properties('name','Standardization', 'cannot_follow','set_makepos', 'follows',{'flt_iir','flt_fir'}, 'independent_channels',true, 'independent_trials',false);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'window_len','WindowLength'}, 30, [], 'Length of normalization window. In seconds.'), ...
    arg_nogui({'state','State'}));

% get rid of NaN's
signal.data(isnan(signal.data(:))) = 0;

% number of data points for our normalization window
N = window_len * signal.srate; %#ok<*NODEF>

% make up prior state if necessary
if isempty(state)
    if size(signal.data,2) < N+1
        error(['For standardization, the data set needs to be longer than the set data window length (for this data set ' num2str(window_len) ' seconds).']); end
    % filter conditions & constant overall data offset (for better numerical accuracy; this is
    % unrelated to the running mean)
    state = struct('ord1',[],'ord2',[],'offset',sum(signal.data,2)/size(signal.data,2));
    % prepend a made up data sequence
    signal.data = [repmat(2*signal.data(:,1),1,N) - signal.data(:,(N+1):-1:2) signal.data];
    prepended = true;
else
    prepended = false;
end

% get raw data X and running mean E[X]
X = bsxfun(@minus,double(signal.data),state.offset);
[X_mean,state.ord1] = moving_average(N,X,state.ord1,2);
% get squared data X^2 and running squared mean E[X^2]
X2 = X.^2;
[X2_mean,state.ord2] = moving_average(N,X2,state.ord2,2);
% compute running std deviation sqrt(E[X^2] - E[X]^2)
X_std = sqrt(X2_mean - X_mean.^2);

% compute standardized data
signal.data = (X - X_mean) ./ X_std;

% trim the prepended part if there was one
if prepended
    signal.data(:,1:N) = []; end

exp_endfun;
