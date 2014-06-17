function signal = flt_selchans(varargin)
% Selects a subset of channels from the given data set.
% Signal = flt_selchans(Signal, Channels)
%
% Channel (or sensor) selection is a simple and effective method to constrain the complexity (and
% thus shorten computation time and/or improve robustness) of later stages in a paradigm. Sometimes,
% it is also employed to approximately restrict a paradigm to a sub-portion of brain processes (by
% using only channels directly above the brain region of interest), but this is not guaranteed to
% have the desired effect, since eletromagnetic signals emitted from any point in the brain are
% practically captured by every sensor (due to volume conduction). Other uses of channel selection
% are to exclude bad channels in a faulty recording or to simulate the behavior of a paradigm
% running on a subset of the sensors (e.g., for cost reduction purposes).
% 
% In:
%   Signal    : Data set
%
%   Channels  : channel indices or names to select
%
% Out:
%   Signal    : The original data set restricted to the selected channels (as far as they are 
%               contained)
%
% Examples:
%   % select only the channels C3, C4 and Cz
%   eeg = flt_selchans(eeg,{'C3','C4','Cz'})
%
%   % select channels 1:32
%   eeg = flt_selchans(eeg,1:32)
%
%   % retain all channels (i.e., do nothing)
%   eeg = flt_selchans(eeg,[])
%
% See also:
%   flt_seltypes, pop_select
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-17

if ~exp_beginfun('filter') return; end

% used as a tool to select channel subsets before these ops are applied
declare_properties('name',{'ChannelSelection','channels'}, 'precedes',{'flt_laplace','flt_ica','flt_reref'}, 'independent_trials',true, 'independent_channels',true);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'channels','Channels'}, [], [], 'Cell array of channel names to retain.','type','cellstr','shape','row'));

subset = set_chanid(signal,channels);
if ~isequal(subset,1:signal.nbchan)
    signal = pop_select(signal,'channel',subset,'sorttrial','off'); end %#ok<*NODEF>

exp_endfun;
