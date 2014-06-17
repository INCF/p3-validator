function signal = flt_window(varargin)
% Select a time portion of the data in an epoched data set.
% Signal = flt_window(Signal, TimeSpec)
%
% flt_select can be used to implement temporal filtering of the data, i.e. selection of a temporal
% portion of the data. Temporal selection is done by specifying a time window (within the epoch)
% and/or a smooth window function, to which the data should be reduced. Temporal filtering is
% usually relevant for the analysis of event-locked processes, which are usually found to be
% localized in some time window near the event. It can also be useful to increase the precision of
% spectral estimates of the data by using a window function with a desirable frequency response [1].
%
% In:
%   Signal   : epoched data set
%
%   TimeSpec : time-domain selection, allows for the specification of an epoch sub-interval and/or
%               a window function, in one of the formats: 
%                * {'windowfunction' windowparameter, [begin end]}
%                * {'windowfunction',windowparameter}
%                * {'windowfunction' [begin end]}
%                * 'windowfunction'
%                * [begin end]
%               where begin/end are in seconds, 'windowfunction' is one of the MATLAB-supplied
%               window functions: 'barthann','bartlett','blackman','blackmanharris','bohman','cheb',
%               'flattop','gauss','hamming','hann','kaiser','nuttall','parzen','rect','taylor',
%               'triang','tukey' The cheb,kaiser and tukey require a window parameter; for other
%               windows, this is optional (see MATLAB's window() for reference). The 'hann' and
%               'gauss' windows are supported without the Signal Processing toolbox.
%
% Out:
%   Signal   :   subset of the data set
%
% Examples:
%   % restrict each epoch of a data set to 0.5s following the time-locking event to 1.5s following
%   % the event
%   eeg = flt_window(eeg,[0.5 1.5])
%
%   % scale the data in each epoch to a Hann window function ranging from the beginning of the 
%   % epoch to its end (implementing a soft selection)
%   eeg = flt_window(eeg,'hann')
%
%   % restrict each epoch to the interval from 1s before the time-locking event to 2s after the 
%   % event, and scale the resulting data by a Kaiser window
%   eeg = flt_window(eeg,{'kaiser' [-1 2]})
%
%   % restrict each epoch to the interval from 1s before the time-locking event to 2s after the 
%   % event, and scale the resulting data by a Kaiser window, using a window parameter (beta) of 3
%   eeg = flt_window(eeg,{'kaiser',3,[-1 2]})
%  
%   % as before, but specifying the two parameters by name
%   eeg = flt_window('Signal',eeg,'TimeSpecification',{'kaiser',3,[-1 2]})
%
%   % as before, but specifing the parts of the TimeSpecification parameter by name instead of 
%   % according to their type:
%   eeg = flt_window('Signal',eeg,'TimeSpecification',{'WindowFunction','kaiser', 'WindowParameter',3, 'TimeRange',[-1 2]})
%
%   % as before, passing the two parameters by position again, but leaving the parts of the TimeSpecification
%   eeg = flt_window(eeg,{'WindowFunction','kaiser', 'WindowParameter',3, 'TimeRange',[-1 2]})
%
%   % as before, but using the short names of the time specification parameter names
%   eeg = flt_window(eeg,{'winfunc','kaiser', 'winparam',3, 'trange',[-1 2]})
%
%   % as before, but omitting the window parameter (falling back to the default, which is 0.5)
%   eeg = flt_window(eeg,{'winfunc','kaiser', 'trange',[-1 2]})
%
%   % retain the original signal (i.e., do noting)
%   eeg = flt_window(eeg,[])
%
% References:
%   [1] Oppenheim, A.V., and R.W. Schafer, "Discrete-Time Signal Processing", 
%       Prentice-Hall, 1989.
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-06-28

if ~exp_beginfun('filter') return; end

declare_properties('name','WindowSelection', 'depends','set_makepos', 'follows','flt_rmbase', 'independent_channels',true, 'independent_trials',true);

arg_define(varargin, ... 
    arg_norep({'signal','Signal'}), ...
    arg_sub({'time','TimeSpecification'}, [], ... 
        {arg({'trange','TimeRange','range'},[],[],'Time window position ([low, high])','shape','row'), ...
         arg({'winfunc','WindowFunction'},'rect',{'barthann','bartlett','blackman','blackmanharris','bohman','cheb','flattop','gauss','hamming','hann','kaiser','nuttall','parzen','rect','taylor','triang','tukey'},'Type of window function. Typical choices are rect (rectangular), hann, gauss, blackman and kaiser.'),...
         arg({'winparam','WindowParameter','param'},[],[],'Parameter of the window function. This is mandatory for cheb, kaiser and tukey and optional for some others.','shape','scalar') ...
        }, 'Time-domain selection. Allows for the specification of a data sub-interval and/or a window function (soft weighting) placed therein.','fmt',@parse_timespec));
    
% time-domain selection
if ~isempty(time) && ~isequal(time,false) %#ok<*USENS>
    % do range selection, if specified
    if ~isempty(time.trange) && ~isequal(time.trange,[signal.xmin signal.xmax]) %#ok<NODEF>
        signal = pop_select(signal,'time',time.trange); end
    
    % apply window function, if specified    
    if ~isempty(time.winfunc)
        wnd = {time.winfunc,size(signal.data,2)};
        if ~isempty(time.winparam)
            wnd{end+1} = time.winparam; end        
        windowmap = struct('barthann',@barthannwin,'bartlett',@bartlett,'blackman',@blackman,'blackmanharris',@blackmanharris,'bohman',@bohmanwin,'cheb',@chebwin,...
            'flattop',@flattopwin,'gauss',@gausswin,'hamming',@hamming,'hann',@hann,'kaiser',@kaiser,'nuttall',@nuttallwin,'parzen',@parzenwin,'rect',@rectwin, ...
            'taylor',@taylorwin,'triang',@triangwin,'tukey',@tukeywin);
        W = repmat(window(windowmap.(wnd{1}),wnd{2:end})',size(signal.data,1),1);
        for t=1:size(signal.data,3)
            signal.data(:,:,t) = signal.data(:,:,t) .* W; end
    end
end

exp_endfun;



% parse the (relatively flexible) time specification into a struct
function out = parse_timespec(in)
out = struct('trange',{[]},'winfunc',{'rect'},'winparam',{[]});
if ~isempty(in)
    % set the .range field
    if isnumeric(in)
        out.trange = in; end
    % set the .winfunc field
    if ischar(in)
        out.winfunc = in; end
    % set fields according to cell contents...
    if iscell(in) 
        rangeidx = find(cellfun(@(x) isnumeric(x) && length(x)==2,in));
        if ~isempty(rangeidx)
            out.trange = in{rangeidx}; end        
        funcidx = find(cellfun(@(x) ischar(x),in));
        if ~isempty(funcidx)
            out.winfunc = in{funcidx}; end        
        paramidx = find(cellfun(@(x) isnumeric(x) && length(x)==1,in));
        if ~isempty(paramidx)
            out.winparam = in{paramidx}; end        
    end
end
% turn into a cell array
out = {out};
