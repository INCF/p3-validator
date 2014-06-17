function [signal,newstate] = flt_fir(varargin)
% Filter a continuous data set by a digital FIR filter.
% [Signal,State] = flt_fir(Signal, Frequencies, Mode, Type, PassbandRipple, StopbandRipple, State)
%
% Digital FIR filters [1] are computationally less efficient than IIR filters, but allow for
% somewhat more control. Specifically, FIR filters can not "blow up" (diverge), even if extremely
% demanding frequency responses are implemented (e.g., drift removal). The computational cost of
% very low-frequency filters during online processing may be prohibitive, though. FIR filters can be
% designed with different phase (delay/distortion) behavior, depending on the desired application.
% Linear phase filters are the most commonly used ones, as they do not distort the data (which makes
% interpretation easier) but only delay it, and because they are causal (i.e. can be used online).
% The delay can, however, easily be too large for certain time-sensitive online tasks (it is a
% function of the lower transition edge). Zero-phase filters are mostly interesting for
% visualization, as they neither delay nor distort the signal, but cannot be used for online
% applications, or within data analyses that estimate online application behavior. Minimum-phase
% filters can be used online, have very low latency, and can implement extreme frequency responses,
% but distort the signal. In that case, some assumptions about signal shape may turn invalid, and
% have to be revised given the filtered data.
% 
% In:
%   Signal        :   continuous data set to be filtered
%
%   Frequencies  :   frequency specification:
%                    * for a low/high-pass filter, this is: [transition-start, transition-end],in Hz
%                    * for a band-pass/stop filter, this is: [low-transition-start,
%                      low-transition-end, hi-transition-start, hi-transition-end], in Hz
%                    * for a free-form filter, this is a cell array of {[frequency, frequency, ...],
%                      [amplitude, amplitude, ...]} (where the amplitudes specify piecewise constant 
%                      regions in the desired filter response, usually between 0 and 1, and the 
%                      frequencies are the lower and upper frequency edge of each of the bands, 
%                      omitting the lower edge of the first band and upper edge of the last band, 
%                      which are assumed to be 0Hz and the Nyquist frequency, respectively) 
%
%                      Alternatively, it can also be a 3xN array of the form;
%                      [freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; ...]
%                      specifying the lower edge, upper edge and amplitude of each constant segment.
%                      The lower edge of the first segment and upper edge of the last segment are 
%                      ignored and assumed as explained above.
%
%   Mode         :   filter mode, 'bp' for bandpass, 'hp' for highpass, 'lp' for lowpass, 'bs' for
%                    bandstop, 'ff' for free-form (default: 'bp')
%
%   Type         :   * 'minimum-phase' minimum-hase filter -- pro: introduces minimal signal delay;
%                       con: distorts the signal (default)
%                    * 'linear-phase' linear-phase filter -- pro: no signal distortion; con: delays
%                       the signal
%                    * 'zero-phase' zero-phase filter -- pro: no signal delay or distortion; con:
%                       can not be used for online purposes
%
%   PassbandRipple  :   maximum allowed relative pass-band ripple; assumed to be in db if negative
%                       (default: -20)
%
%   StopbandRipple  :   maximum allowed relative stop-band ripple; assumed to be in db if negative
%                       (default: -30)
%
%   State        :   previous filter state, as obtained by a previous execution of flt_fir on an
%                    immediately preceding data set (default: [])
%
% Out: 
%   Signal       :  filtered, continuous data set
%   State        :  state of the filter, after it got applied
%
% Examples:
%   % use a 7-30 Hz bandpass filter, with transition regions that are 2 Hz wide
%   eeg = flt_fir(eeg,[6 8 29 31])
%
%   % use a 1Hz highpass filter (with a transition between 0.9 and 1.1 Hz)
%   eeg = flt_fir(eeg,[0.9 1.1],'highpass')
%
%   % use a 1Hz highpass filter (with very generous transition region) that is linear phase (i.e. 
%   % does not distort the signal)
%   eeg = flt_fir(eeg,[0.5 1.5],'highpass','linear-phase')
%
%   % use a 7.5-30 Hz bandpass filter, with transition regions that are 5 Hz wide, and a particular
%   % specification of pass-band and stop-band rippling constraints, passing all arguments by name
%   eeg = flt_fir('Signal',eeg,'Frequencies',[5 10 27.5 32.5],'PassbandRipple',-10,'StopbandRipple',-50);
%
%   % as previous, but using the short argument names
%   eeg = flt_fir('signal',eeg,'fspec',[5 10 27.5 32.5],'passripple',-10,'stopripple',-50);
%
%   % implement a free-form FIR filter with peaks within 12-15 Hz and within 26-35 Hz
%   eeg = flt_fir(eeg,[0 11 0; 12 15 1; 16 25 0; 26 35 1; 36 100 0],'freeform')
%
% Notes:
%   The designed filter is optimal in terms of maximum absolute error (as opposed to mean square
%   error). The Signal Processing Toolbox is required.
%
% References:
%   [1] A.V. Oppenheim and R.W. Schafer, "Digital Signal Processing",
%       Prentice-Hall, 1975.
%
% See also:
%   firpm, filter
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-17  

if ~exp_beginfun('filter') return; end

% does not make sense on epoched data
declare_properties('name','FIRFilter', 'follows','flt_iir', 'cannot_follow','set_makepos', 'independent_channels',true, 'independent_trials',true);

arg_define(varargin, ... 
    arg_norep({'signal','Signal'}), ...
    arg({'fspec','Frequencies'}, [], [], ['Frequency specification of the filter. For a low/high-pass filter, this is: [transition-start, transition-end], in Hz and for a band-pass/stop filter, this is: [low-transition-start, low-transition-end, hi-transition-start, hi-transition-end], in Hz.' ...
                                          'For a free-form filter, this is a 2d matrix of the form [frequency,frequency,frequency, ...; amplitude, amplitude, amplitude, ...] or [frequency,frequency,frequency, ...; amplitude, amplitude, amplitude, ...; ripple, ripple, ripple, ...]']), ...
    arg({'fmode','Mode'}, 'bandpass', {'bandpass','highpass','lowpass','bandstop','freeform'}, 'Filtering mode. Determines how the Frequencies parameter is interpreted.'), ...
    arg({'ftype','Type'},'minimum-phase', {'minimum-phase','linear-phase','zero-phase'}, 'Filter type. Minimum-phase introduces only minimal signal delay but distorts the signal. Linear-phase has no signal distortion but delays the signal. Zero-phase has neither signal delay nor distortion but can not be used for online purposes.'), ...
    arg({'passripple','PassbandRipple'}, -20, [-180 1], 'Maximum relative rippling in pass-band. Assumed to be in db if negative, otherwise taken as a ratio.'), ...
    arg({'stopripple','StopbandRipple'}, -30, [-180 1], 'Maximum relative rippling in stop-band. Assumed to be in db if negative, otherwise taken as a ratio.'), ...
    arg_nogui({'state','State'}));


if passripple < 0 %#ok<*NODEF>
    passripple = 10^(passripple/10); end
if stopripple < 0
    stopripple = 10^(stopripple/10); end

% phase 1: design the filter if necessary
if iscell(fspec) && length(fspec)==1
    % called with precomputed filter coefficients
    b = fspec{1};
else
    fmode = hlp_rewrite(fmode,'bandpass','bp','highpass','hp','lowpass','lp','bandstop','bs','freeform','ff');
    % create filter specification
    amp_table = struct('bp',[0 1 0],'bs',[1 0 1],'lp',[1 0],'hp',[0 1]);    
    if ~strcmp(fmode,'ff')
        % a standard frequency spec was given; look up the corresponding amplitude vector from a table
        fspec = {fspec,amp_table.(fmode)}; 
    else
        % a free-form frequency spec is given
        if iscell(fspec)
            % given as a cell array of {bandfreqs,amps} or {bandfreqs, amps, ripple}
            if length(fspec{1}) == 2*length(fspec{2})
                error('When specifying the bands for each constant-amplitude region of the filter response, the first band is assumed to begin at 0Hz and the last band is assumed to end at the Nyquist frequency -- thus, these 2 numbers in the band specification should be omitted.'); 
            elseif length(fspec{1}) ~= 2*length(fspec{2})-2
                error('The specification of band edges does not match the specification of band amplitudes; for each band, a lower and an upper edge frequency must be listed, and both the lower edge of the first band and upper edge of the last band must be omitted (they equal 0Hz and the Nyquist frequency, respectively).');
            end
        elseif ~isvector(fspec)
            if size(fspec,2) == 3
                bands = fspec(:,1:2)'; 
                fspec = {bands(2:end-1),fspec(:,3)'};
            elseif size(fspec,1) == 4
                bands = fspec(:,1:2)'; 
                fspec = {bands(2:end-1),fspec(:,3)',fspec(:,4)'};
            else
                error('When specifying the piecewise-constant filter design in matrix form, a 3xB or 4xB matrix (B = number of bands) of the form [freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; ...] or [freq_lo,freq_hi,amp,ripple; freq_lo,freq_hi,amp,ripple; ...] must be given.');
            end
        else
            error('When specifying the piecewise-constant filter design in matrix form, a 3xB or 4xB matrix (B = number of bands) of the form [freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; freq_lo,freq_hi,amp; ...] or [freq_lo,freq_hi,amp,ripple; freq_lo,freq_hi,amp,ripple; ...] must be given.');
        end
    end
    if length(fspec) < 3
        % derive the rippling specification from the amplitudes and passripple/stopripple
        fspec{3} = stopripple + fspec{2}*(passripple-stopripple); end    
    if strcmp(ftype,'zero-phase')
        % filter is being applied twice: correct for that
        fspec{2} = sqrt(fspec{2}); end
    % design the filter as minimax-optimal
    try
        c = firpmord(fspec{:},signal.srate,'cell');
    catch e
        if strcmp(e.identifier,'MATLAB:UndefinedFunction')
            error('BCILAB:flt_fir:no_license','Apparently you don''t have a Signal Processing Toolbox license, so you cannot use the FIRFilter.\nYou can replace this filter in the "Review/Edit approach" dialog by disabling it and turning on a SpectralSelection filter instead. If you are using a standard paradigm, you may also look for an equivalent of it that does not require the SigProc toolbox (these are at the bottom of the list under "New Approach").');
        else
            rethrow(e);
        end
    end
    b = hlp_microcache('fdesign',@firpm,max(3,c{1}),c{2:end});
    if strcmp(ftype,'minimum-phase')
        if any(abs(fft(b)) < 0.0001)
            b = b+randn(1,length(b))*0.0001; end
        % minimze the phase
        [dummy,b] = rceps(b); %#ok<ASGLU>
    end 
    % and normalize magnitude...
    b = b/abs(max(freqz(b)));
end

% phase 2: filter the data
sig = double(signal.data)';
if ~exist('state','var')
    state = []; end
if isempty(state) 
    % offline case; we need to prepend the signal with a mirror section of itself, to minimize
    % start-up transients
    sig = [repmat(2*sig(1,:),length(b),1) - sig((length(b)+1):-1:2,:); sig]; 
    if strcmp(ftype,'zero-phase')
        % to get a zero-phase filter, we run the filter backwards first
        % reverse the signal and prepend it with a mirror section (to minimize start-up transients)
        sig = sig(end:-1:1,:); sig = [repmat(2*sig(1,:),length(b),1) - sig((length(b)+1):-1:2,:); sig];
        % run the filter
        sig = filter_fast(b,1,sig);
        % reverse and cut startup segment again
        sig = sig(end:-1:(length(b)+1),:);
    end
else
    % online case: check for misuses
    if strcmp(ftype,'zero-phase')
        error('zero-phase filters are non-causal and cannot be run online (or on continued data); use linear-phase or minimum-phase filters, or flt_iir.'); end
end

% apply the filter
[sig,newstate] = filter_fast(b,1,sig,state,1);

% check if we need to cut off a data segment that we previously prepended
if isempty(state)    
    sig(1:length(b),:) = []; end

% write the data back
signal.data = sig';

% in the online expression, replace fspec by {b}
exp_endfun('append_online',{'fspec',{b}});
