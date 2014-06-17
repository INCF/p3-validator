function [signal,state] = flt_resample(varargin)
% Changes the sampling rate of a given data set.
% [Signal,State] = flt_resample(Signal, SamplingRate, FilterLength, State)
%
% Resampling [1] is usually applied to reduce the computational cost of certain methods, by running
% them on a signal sampled at a lower rate. Other reasons to resample data are to save memory, to
% improve a method's robustness (by reducing its number of parameters) or to align and/or unify
% signals originally sampled at different rates. Resampling has two drawbacks that require
% consideration: first, it may under some conditions create frequency artifacts (called aliasing),
% which can be amplified by the adaptive information-extracting nature of later stages in most BCI
% paradigms; in the worst case, this can lead to scientifically invalid conclusions. Second, it
% introduces a delay into the signal (usually on the order of 10-100ms), which may be prohibitive in
% very time-critical online scenarios. If absolutely necessary, this delay can be mitigated by the
% use of some specialized (signal-distorting and/or more aliasing-prone) resamplers.
%
% In:
%   Signal          : continuous data set to be resampled
%
%   SamplingRate    : the new sample rate
%
%   FilterLength    : length of the filter kernel to use (in the original time series) (default: 10)
%
%   WindowParameter : design parameter for the low-pass Kaiser window (default: 5)
%
%   State           : state of a previous filter invocation
%
% Out:
%   Signal : a resampled data set
%
%   State  : state after application of the filter
%
% Examples:
%   % resample to 100Hz
%   eeg = flt_resample(eeg,100);
%
%   % resample to 100Hz, passing arguments by name
%   eeg = flt_resample('Signal',eeg,'SamplingRate',100);
%
%   % resample to 100Hz and put a very high weight on the stop-band of the anti-aliasing filter
%   eeg = flt_resample('Signal',eeg,'SamplingRate',100,'StopbandWeight',10);
%
%   % resample to 100Hz and use a particularly long anti-aliasing filter (30 taps)
%   eeg = flt_resample(eeg,100,30);
%
%   % retain original sampling ate (i.e., do nothing)
%   eeg = flt_resample(eeg,[])
%
%
% References:
%  [1] Proakis, J., and Manolakis, D. "Digital Signal Processing: Principles, Algorithms and Applications."
%      Macmillan Publishing Company, 1992.
%
% See also:
%   upfirdn2
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-03-28

if ~exp_beginfun('filter') return; end

% usually speeds up all subsequent computations
declare_properties('name',{'Resampling','srate'}, 'precedes',{'flt_selchans','flt_reref','flt_laplace','flt_ica','flt_iir','flt_fir','flt_standardize','set_makepos'}, 'independent_channels',true, 'independent_trials',true);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'srate','SamplingRate'}, [], [], 'New sampling rate of the data.','shape','scalar'), ...
    arg({'fltlen','FilterLength'}, 10, [], 'Filter length. This determines both the quality and the delay of the resampling. The default should be fine.','shape','scalar'), ...
    arg({'stopweight','StopbandWeight'}, 1, [], 'Stop-band weight. Relative weight of the stop-band.','shape','scalar'), ...
    arg_norep({'state','State'},unassigned));

% if no srate is specified, we adopt the sampling rate of the signal
if isempty(srate)  %#ok<*NODEF>
    srate = signal.srate; end

% sanity check
if size(signal.data,3) > 1
    error('flt_resample is supposed to be applied to continuous (non-epoched) data.'); end

% need to resample?
if srate ~= signal.srate
    % do we have previous state?
    if ~exist('state','var')
        % find rational resampling factors
        [p,q] = rat(srate/signal.srate, 0.001);
        % design resampling filter
        pqmax = max(p,q);
        cutoff = 1/2/pqmax;
        len = 2*fltlen*pqmax + 1;
        H = p*firlp(len,2*cutoff,2*cutoff,stopweight) .* lanczos(len);
        H = [zeros(1,floor(q-mod((len-1)/2,q))) H(:).'];
        % construct state struct
        state = struct('conds',[],'H',H,'p',p,'q',q);
    end
    
    % resample the data itself
    signal.data = single(signal.data)';
    [tmp,state.conds] = upfirdn2(signal.data,state.H,state.p,state.q,state.conds);
    signal.data = tmp';
    % update signal meta-data
    signal.icaact = [];
    signal.srate = srate;
    signal.pnts = size(signal.data,2);
    signal.xmax = signal.xmin + (signal.pnts-1)/signal.srate;
    if isfield(signal,'event') && isfield(signal.event,'latency')
        [signal.event.latency] = arraydeal([signal.event.latency]*state.p/state.q); end
    if isfield(signal,'urevent') && isfield(signal.urevent,'latency')
        [signal.urevent.latency] = arraydeal([signal.urevent.latency]*state.p/state.q); end
end

exp_endfun;


function varargout = arraydeal(arr)
varargout = num2cell(arr);

function w = lanczos(N)
w = sinc(2*(1:N)/(N-1)-1);

function y = sinc(x)
y = ones(size(x));
n = x~=0;
y(n) = sin(pi*x(n))./(pi*x(n));
