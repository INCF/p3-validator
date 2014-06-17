function [signal,state] = flt_iir(varargin)
% Filter a continuous data set by a digital IIR lowpass/highpass/bandpass/bandstop filter.
% [Signal,State] = flt_iir(Signal, Frequencies, Mode, Type, Attenuation, Ripple, State)
%
% Digital IIR filters [1] are efficient for both offline and online analysis. They distort the
% signal, but introduce relatively low delay (comparable to minimum-phase FIR filters), so that the
% latency of a BCI is only marginally increased by adding an IIR filter. However, IIR filters are
% numerically sensitive (they can "blow up"), and therefore, extreme frequency responses (e.g.,
% low-frequency 'brickwall' filters) can often not be satisfactorily implemented. In these cases,
% FIR or FFT filters (flt_fir or flt_select, respectively) can be used as a fall-back.
%
% In:
%   Signal       :   continuous data set to be filtered
%
%   Frequencies  :   frequency specification:
%                    * for a low/high-pass filter, this is: [transition-start, transition-end],in Hz
%                    * for a band-pass/stop filter, this is: [low-transition-start,
%                      low-transition-end, hi-transition-start, hi-transition-end], in Hz
%
%   Mode         :   filter mode, 'bp' for bandpass, 'hp' for highpass, 'lp' for lowpass,
%                    'bs' for bandstop (default: 'bp')
%
%   Type         :   'butter' for a Butterworth filter -- pro: flat response overall; con: slow
%                             attenuation (default)
%                    'cheb1' for a Chebychev Type I filter -- pro: steep attennuation; con:
%                                 strong passband ripple
%                    'cheb2' for a Chebychev Type II filter -- pro: flat
%                                 passband response; con: slower
%                                 attenuation than cheb1
%                    'ellip' for an Elliptic filter -- pro: steepest rolloff, lowest latency;
%                               con: passband ripple
%
%   Attenuation  :   stop-band attenuation, in db, default: 50
%
%   Ripple       :   maximum allowed pass-band ripple, in db, default: 3
%
%   State        :   previous filter state, as obtained by a previous execution of flt_iir on an
%                    immediately preceding data set (default: [])
%
%
% Out:
%   Signal       :  filtered, continuous EEGLAB data set
%
%   State        :  state of the filter, can be used to continue on a subsequent portion of the data
%
% Examples:
%   % apply a 7-30 Hz IIR filter with generous transition regions
%   eeg = flt_iir(eeg,[5 10 25 35])
%
%   % apply a 1Hz highpass filter with 1Hz transition bandwidth
%   eeg = flt_iir(eeg,[0.5 1.5],'highpass')
%
%   % apply a 45-55 Hz notch filter for east european line noise
%   eeg = flt_iir(eeg,[40 45 55 60],'bandstop')
%
%   % apply a 45-55 Hz notch filter with Chebychev Type I design, passing all arguments by name
%   eeg = flt_iir('Signal',eeg,'Frequencies',[40 45 55 60],'Mode','bandstop','Type','chebychev1')
%   
%
% References:
%  [1] T. W. Parks and C. S. Burrus, "Digital Filter Design",
%      John Wiley & Sons, 1987, chapter 7.
%
% See also:
%   butter, cheby1, cheby2, ellip, dfilt, filter
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-17

if ~exp_beginfun('filter') return; end

% running after the FIR can improve numeric stability; makes no sense on epoched data
declare_properties('name','IIRFilter', 'cannot_follow','set_makepos', 'independent_channels',true, 'independent_trials',true);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'f','Frequencies'}, [], [], 'Frequency specification of the filter. For a low/high-pass filter, this is: [transition-start, transition-end], in Hz and for a band-pass/stop filter, this is: [low-transition-start, low-transition-end, hi-transition-start, hi-transition-end], in Hz.','shape','row'), ...
    arg({'fmode','Mode'}, 'bandpass', {'bandpass','highpass','lowpass','bandstop'}, 'Filtering mode. Determines how the Frequencies parameter is interpreted.'), ...
    arg({'ftype','Type'},'butterworth', {'butterworth','chebychev1','chebychev2','elliptic'}, 'Filter type. Butterworth has a flat response overall but a slow/gentle rolloff. Chebychev Type I has a steep rolloff, but strong passband ripples. Chebychev Type II has a flat passband response, but a slower rolloff than Type I. The elliptic filter has the steepest rolloff (or lowest latency at comparable steepness) but passband rippling.'), ...
    arg({'atten','Attenuation'}, 50, [0 180], 'Minimum signal attenuation in the stop band. In db.'),...
    arg({'ripple','Ripple'}, 0.5, [0 60], 'Maximum peak-to-peak ripple in pass band. In db.'), ...
    arg_norep({'state','State'},unassigned));

if size(signal.data,3) > 1
    error('flt_iir is supposed to be applied to continuous (non-epoched) data.'); end

% need to create dfilt state object?
if ~exist('state','var')
    if ~exist('dfilt','file')
        error('You need the Signal Processing toolbox to make use of IIR filters in BCILAB.'); end
    % rewrite some parameters to shortcut forms
    fmode = hlp_rewrite(fmode,'bandpass','bp','highpass','hp','lowpass','lp','bandstop','bs');
    ftype = hlp_rewrite(ftype,'butterworth','butt','chebychev1','cheb1','chebychev2','cheb2','elliptic','ellip');
    % compute filter order
    f = 2*f/signal.srate;
    if length(f) < 4 && any(strcmp(fmode ,{'bp','bs'}))
        error('For an IIR bandpass/bandstop filter, four frequencies must be specified.'); end
    switch fmode
        case 'bp'
            [Wp,Ws,label] = deal(f([2,3]),f([1,4]),{});
        case 'bs'
            [Wp,Ws,label] = deal(f([1,4]),f([2,3]),{'stop'});
        case 'lp'
            [Wp,Ws,label] = deal(f(1),f(2),{'low'});
        case 'hp'
            [Wp,Ws,label] = deal(f(2),f(1),{'high'});
    end
    try
        [n,Wn] = feval([ftype 'ord'],Wp,Ws,ripple,atten);
    catch e
        if strcmp(e.identifier,'MATLAB:UndefinedFunction')
            error('BCILAB:flt_iir:no_license','Apparently you don''t have a Signal Processing Toolbox license, so you cannot use the IIRFilter.\nYou can replace this filter in the "Review/Edit approach" dialog by disabling it and turning on a SpectralSelection filter instead. If you are using a standard paradigm, you may also look for an equivalent of it that does not require the SigProc toolbox (these are at the bottom of the list under "New Approach").');
        else
            rethrow(e);
        end
    end

    % compute filter coefficients (in Zero-Pole-Gain form, to prevent instability)
    switch ftype
        case 'butt'
            [z,p,k] = butter(n,Wn,label{:});
        case 'cheb1'
            [z,p,k] = cheby1(n,ripple,Wn,label{:});
        case 'cheb2'
            [z,p,k] = cheby2(n,atten,Wn,label{:});
        case 'ellip'
            [z,p,k] = ellip(n,ripple,atten,Wn,label{:});
    end
    [sos,g] = zp2sos(z,p,k);
    state = dfilt.df2sos(sos,g);
    state = dfilt.df2sos(sos,g/max(abs(freqz(state)))); 
    set(state,'PersistentMemory',true);
elseif ~onl_isonline
    % make a deep copy of the state; not necessary during online processing
    state = copy(state);
end

% apply the filter
signal.data = filter(state,double(signal.data),2);

exp_endfun;
