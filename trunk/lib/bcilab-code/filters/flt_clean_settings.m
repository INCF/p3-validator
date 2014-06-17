function signal = flt_clean_settings(varargin)
% Clean EEG data according to a particular cleaning setting.
% Signal = flt_clean_settings(Signal,Setting)
%
% This function calls the other cleaning functions according to a particular cleaning setting.
% Note: The signal should be re-referenced appropriately before running this (e.g. to the mastoids).
%
% In:
%   Signal   : continuous data set to process
%
%   Setting  : Degree of data cleaning to apply. The default assumes a relatively well-controlled
%              lab experiment, containing only a few isolated artifacts (e.g. occasional movements,
%              a broken channel). The higher levels assume incrementally more noisy data (i.e.,
%              longer periods of artifacts, more broken channels, etc.).
%
%              Note that each of these levels has sub-parameters which can be selectively overridden
%              by passing the CleaningLevel as a cell arrays, as in: 
%               {'seated', 'DriftCutoff',[0.25 1], 'BadChannelRemoval', {'MinimumCorrelation',0.25, 'WindowLength',0.5}}
%
%              The arguments that can be passed to customize a cleaning level are the following:
%               'DriftCutoff'       : frequency specification of the drift-correction filter
%                                     (this is passed on to flt_fir)
%               'BadWindowRemoval   : parameters that control the removal of bad time windows
%                                     (all parameters of flt_clean_windows are applicable here)
%               'BadChannelRemoval' : parameters that control the removal of bad channels
%                                     (all parameters of flt_clean_channels are applicable here)
%               'BadSubspaceRemoval': parameters that control the removal of local (in time and
%                                     space) artifact subspaces of the data; note that, since
%                                     artifacts are being replaced by zeros here, a subtle coupling
%                                     between the resulting data statistics and the original
%                                     artifacts is being introduced (all parameters of
%                                     flt_clean_peaks are applicable here)
%               'SpectrumShaping'   : parameters of a final FIR filter to reshape the spectrum
%                                     of the data arbitrarily (usually disabled) (all parameters of
%                                     flt_fir are applicable here)
%
%   HaveBrokenChannels : Whether the data may have broken channels (default: true).
%
%   HaveChannelDropouts : Whether the data may have channels that drop out and come back in (default: false).
%                         Note: this is somewhat slow (esp. for > 64 channels), thus disabled by default.
%
%   HaveSpikes : Whether the data may contain spikes (default: false). Note: the spike algorithm
%                is currently not handling drifing data properly.
%
%   HaveBursts : Whether the data may contain local bursts or peaks (in subspaces). 
%                Only useful for engineering purposes as this will obliterate a fraction of the EEG 
%                in ways that are hard to reason about in neuroscience studies. (default: false)
%
%   LinearArtifactReference : optional list of channels that contain reference artifact signals
%                             to regress out (such as EOG, EMG, EM probe, trigger channels, ...)
%                             (default: {})
%
%   LinearReferenceLength : The length of the assumed temporal dependencies between artifact channel 
%                           content and EEG channel contents, in samples. Can get slow if this is very 
%                           long (e.g., when removing entire VEPs). (default: 3)
%
% Out:
%   Signal : cleaned data set
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2012-01-27

if ~exp_beginfun('offline') return; end;


% a function that creates a list of cleaning parameters, for some defaults
make_clean_params = @(drifts,windows,channels,dropouts,peaks,spikes,shaping) { ...
    arg({'drifts','DriftCutoff'},drifts,[],'Drift-correction high-pass filter. This is the frequency specification of a (zero-phase) filter: [transition-start, transition-end], in Hz'), ...
    arg_subtoggle({'windows','BadWindowRemoval'},windows,@flt_clean_windows,'Rejection of time windows with excessive signal power.'), ...
    arg_subtoggle({'channels','BadChannelRemoval'},channels,@flt_clean_channels,'Rejection of channels with uncorrelated signals.'), ...
    arg_subtoggle({'dropouts','ChannelDropoutRepair'},dropouts,@flt_repair_channels,'Repair of channels that temporarily drop out.'), ...
    arg_subtoggle({'pcasubspace','BadSubspaceRemoval','peaks'},peaks,@flt_clean_peaks,'Rejection of high-power subspaces per window. This is very experimental, and should not be used for publication-related work.'), ...
    arg_subtoggle({'pcaspikes','SpikeSubspaceRemoval','spikes'},spikes,@flt_clean_peaks,'Rejection of spike subspaces. This is very experimental, and should not be used for publication-related work.'), ...
    arg_subtoggle({'shaping','SpectrumShaping'},shaping,@flt_fir,'Reshaping of the signal spectrum. Done using a FIR filter.')};

% define arguments
arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg_subswitch({'cleansetting','DataSetting'},'seated', ...
        {'off',make_clean_params([],[],[],[],[],[],[]), ...
         'seated',make_clean_params([0.5 1],{'flag_quantile',0.16},{'min_corr',0.4},{'min_corr',0.4},{'remove_quantile',0.05},[],[]), ...
         'noisy',make_clean_params([0.5 1],{'flag_quantile',0.2},{'min_corr',0.5},{'min_corr',0.5},{'remove_quantile',0.1},[],[]), ...
         'walking',make_clean_params([0.5 1],{'flag_quantile',0.275},{'min_corr',0.6},{'min_corr',0.6},{'remove_quantile',0.15},[],[]), ...
         'running',make_clean_params([0.5 1],{'flag_quantile',0.3},{'min_corr',0.65},{'min_corr',0.65},{'remove_quantile',0.25},[],[]), ...
         'sprinting',make_clean_params([0.5 1],{'flag_quantile',0.4},{'min_corr',0.7},{'min_corr',0.7},{'remove_quantile',0.35},[],[]), ...
        },'Data artifact level. Determines the aggressiveness of the cleaning functions (generally, the setting translates into the fraction of data that is assumed to be potentially bad).'), ...
    arg({'have_broken_chans','HaveBrokenChannels'},true,[],'Broken channels. Whether the data may contain broken channels.'), ...
    arg({'have_channel_dropouts','HaveChannelDropouts'},false,[],'Channels drop-outs. Whether the data may contain channels that temporarily drop out and come back.'), ...
    arg({'have_spikes','HaveSpikes'},false,[],'Spikes in the data. Whether the data may contain spikes.'), ...
    arg({'have_bursts','HaveBursts'},false,[],'Remove bursts from data. Whether the data may contain local bursts or peaks (in subspaces). Only useful for engineering purposes as this will obliterate a fraction of the EEG in ways that are hard to reason about in neuroscience studies.'), ...
    arg({'linear_reference','LinearArtifactReference'},[],[],'Linear artifact reference channel(s). Labels of any channels that are direct measures of artifacts that shall be removed. Can get slow if you have many such channels (e.g., neckband).','type','cellstr','shape','row'),...
    arg({'reference_len','LinearReferenceLength'},3,[],'Linear reference length. The length of the assumed temporal dependencies between artifact channel content and EEG channel contents, in samples. Can get slow if this is very long (e.g., when removing entire VEPs).'));

% remove signal mean
signal = flt_rmbase(signal);

% --- spike removal ---

% remove local spikes using a dedicated spike cleaner
if have_spikes
    signal = flt_clean_spikes('signal',signal); end

% --- high-pass drift correction ---

% remove drifts using an FIR filter
if ~isempty(cleansetting.drifts)
    signal = flt_iir(signal,cleansetting.drifts,'highpass'); end

% --- linear reference removal ---

% regress out any linearly related artifact contents in the EEG signal (and remove the reference channels, too)
if ~isempty(linear_reference)
    signal = flt_eog('signal',signal,'eogchans',linear_reference,'removeeog',true,'kernellen',reference_len); end

% --- bad window removal ---

% remove extreme data periods using a signal power measure
if cleansetting.windows.arg_selection
    signal = flt_clean_windows(cleansetting.windows,'signal',signal); end

% --- bad channel removal ---

% remove bad channels using a correlation measure
if have_broken_chans && cleansetting.channels.arg_selection
    signal = flt_clean_channels(cleansetting.channels,'signal',signal); end

% --- channel dropout handling ---

if have_channel_dropouts && cleansetting.dropouts.arg_selection
    signal = flt_repair_channels(cleansetting.dropouts,'signal',signal); end

% --- aggressive methods (currently unused in the default settings) ---

% remove local peaks using windowed PCA
if have_bursts && cleansetting.pcasubspace.arg_selection
    signal = flt_clean_peaks(cleansetting.pcasubspace,'signal',signal); end

% remove local spikes using windowed PCA (short local peaks)
if cleansetting.pcaspikes.arg_selection
    signal = flt_clean_peaks(cleansetting.pcaspikes,'signal',signal); end

% run a signal-shaping final FIR filter
if cleansetting.shaping.arg_selection
    signal = flt_fir(cleansetting.shaping,'signal',signal); end


% evaluate the signal
signal = exp_eval_optimized(signal);

exp_endfun;
