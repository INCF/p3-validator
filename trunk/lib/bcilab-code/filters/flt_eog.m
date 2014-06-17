function [signal,state] = flt_eog(varargin)
% Remove EOG artifacts from EEG using EOG reference channels.
% [Signal,State] = flt_eog(Signal, EOGChannels, ForgetFactor, KernelLength)
%
% This is an online filter that operates on continuous data, and removes EOG using a regression
% technique, if EOG channels are present (using recursive least squares) [1]. Note that noise in
% the EOG signals may be transferred onto the EEG channels.
%
% In:
%   Signal       :   continuous data set to be filtered
%
%   EOGChannels  :   list of EOG channel indices or cell array of EOG channel names
%                    (default: [] = try to auto-detect)
%
%   ForgetFactor :   forgetting factor of the adaptive filter; amounts to a choice of the 
%                    effective memory length (default: 0.9999)
%
%   KernelLength ;   length/order of the temporal FIR filter kernel (default: 3)
%
%   RemoveEOG    :   whether to remove the EOG channels after processing (default: false)
%
%   State        :   previous filter state, as obtained by a previous execution of flt_eog on an
%                    immediately preceding data set (default: [])
%
% Out:
%   Signal       :  filtered, continuous EEGLAB data set
%
%   State        :  state of the filter, can be used to continue on a subsequent portion of the data
%
% Examples:
%   % using the defaults
%   eeg = flt_eog(eeg)
%
%   % manually supply EOG channels
%   eeg = flt_eog(eeg,{'veog','heog'});
%
%   % pass a specific forgetting factor (here: by name)
%   eeg = flt_eog('Signal',eeg,'ForgetFactor',0.9995)
%
% References:
%  [1] P. He, G.F. Wilson, C. Russel, "Removal of ocular artifacts from electro-encephalogram by adaptive filtering"
%      Med. Biol. Eng. Comput. 42 pp. 407-412, 2004
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-17

if ~exp_beginfun('filter') return; end

% makes no sense on epoched data (and should precede the major spatial filters)
declare_properties('name','EOGRemoval', 'precedes','flt_project', 'cannot_follow',{'set_makepos','flt_ica'}, 'independent_channels',true, 'independent_trials',true);

arg_define(varargin, ...
    arg_norep({'signal','Signal'}), ...
    arg({'eogchans','EOGChannels'}, [], [], 'EOG Channels. Names or indices of EOG channels.'), ...
    arg({'ffact','ForgetFactor'}, 0.9995, [0.99 1], 'Forgetting factor. Determines the memory length of the adaptive filter.'), ...
    arg({'kernellen','KernelLength'},3, [], 'Kernel Length. The length/order of the temporal FIR filter kernel.'), ...
    arg({'removeeog','RemoveEOG'},false, [], 'Remove EOG channels. Remove the EOG channels after processing.'), ...
    arg_norep({'state','State'},unassigned));

if size(signal.data,3) > 1
    error('flt_eog is supposed to be applied to continuous (non-epoched) data.'); end

% initialize the state, if necessary
if ~exist('state','var')
    % figure out what the EOG channels are
    if isempty(eogchans)
        eogchans = find(strcmp({signal.chanlocs.type},'EOG'));
    else
        eogchans = set_chanid(signal,eogchans);
    end
    if isempty(eogchans)
        error('Could not find EOG channels in the data; please specify the names / indices of EOG channels explicitly.'); end
    state.eog = eogchans;                          % eog channel indices
    state.eeg = setdiff(1:signal.nbchan,eogchans); % eeg channel indices
    state.neog = length(state.eog);                % number of eog channel indices
    
    % initialize RLS filter state
    state.hist = zeros(state.neog,kernellen);     % hist is the block of the M last eog samples in matrix form
    state.R_n = eye(state.neog * kernellen) / 0.01; % R(n-1)^-1 is the inverse matrix
    state.H_n = zeros(state.neog*kernellen,length(state.eeg));  % H(n-1) is the EOG filter kernel
end

% apply filter
[X,state.hist,state.H_n,state.R_n] = compute(signal.data,state.hist,state.H_n,state.R_n,state.eeg,state.eog,ffact);

if removeeog
    % Note: the proper way would be to use pop_select...
    signal.data = X(state.eeg,:);
    signal.nbchan = size(signal.data,1);
    signal.chanlocs = signal.chanlocs(state.eeg);
else
    signal.data = X;
end

exp_endfun;


function [X,hist,H_n,R_n] = compute(X,hist,H_n,R_n,eeg,eog,ffact)
% for each sample...
for n=1:size(X,2)
    % update the EOG history by feeding in a new sample
    hist = [hist(:,2:end) X(eog,n)];
    % vectorize the EOG history into r(n)        % Eq. 23
    tmp = hist';
    r_n = tmp(:);
    
    % calculate K(n)                             % Eq. 25
    K_n = R_n * r_n / (ffact + r_n' * R_n * r_n);
    % update R(n)                                % Eq. 24
    R_n = ffact^-1 * R_n - ffact^-1 * K_n * r_n' * R_n;
    
    % get the current EEG samples s(n)
    s_n = X(eeg,n);    
    % calculate e(n/n-1)                         % Eq. 27
    e_nn = s_n - (r_n' * H_n)';    
    % update H(n)                                % Eq. 26
    H_n = H_n + K_n * e_nn';
    % calculate e(n), new cleaned EEG signal     % Eq. 29
    e_n = s_n - (r_n' * H_n)';
    % write back into the signal
    X(eeg,n) = e_n;
end
