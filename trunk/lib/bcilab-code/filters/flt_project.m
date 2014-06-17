function signal = flt_project(varargin)
% Spatially project the given data set, e.g. to apply an IC decomposition
% Signal = flt_project(Signal, ProjectionMatrix, ChannelNames)
%
% In:
%   Signal           : epoched or continuous EEGLAB data set
%
%   ProjectionMatrix : projection matrix to apply; if left empty, flt_project will try to apply the
%                      ICA unmixing matrix of the data set (if present)
%
%   ChannelNames     : optional cell array of new channel names (default: {'1','2','3',...})
%
%   ComponentSubset  : List of component indicies to which the result shall be restricted; can also 
%                      be expressed as fractional intervals as in [0.1 0.3; 0.7 0.9], denoting components
%                      from 10% to 30%, and 70% to 90% of the number of components. (default: [] = retain all);
%
%   ChannelSubset    : List of channel indices to which the data shall be restricted prior to 
%                      application of the matrix (default: [] = retain all);
%
% Out:
%   Signal : projected EEGLAB data set
% 
% Examples:
%   % project onto a 10-dimensional random subspace, assuming that there are 32 channels in the data
%   eeg = flt_project(eeg,randn(10,32))
%
%   % project onto a 10-dimensional random subspace, and pass some alphabetic channel names
%   eeg = flt_project(eeg,randn(10,32),{'A','B','C','D','E','F','G','H','I','J'})
%
%   % project using some independent component decomposition
%   eeg = flt_project(eeg,eeg.icaweights*eeg.icasphere)
%
%   % project using some independent component decomposition, passing arguments by name
%   eeg = flt_project('Signal',eeg,'ProjectionMatix',eeg.icaweights*eeg.icasphere)
%
% See also:
%   flt_ica, flt_stationary, flt_laplace, flt_selchans
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-03-28

if ~exp_beginfun('filter') return; end;

% would be reverted by an ICA
declare_properties('name','Projection', 'follows','flt_ica', 'independent_channels',false, 'independent_trials',true);

arg_define(varargin,...
    arg_norep({'signal','Signal'}), ...
    arg({'pmat','ProjectionMatrix'}, [], [], 'Projection matrix. The data is multiplied by this matrix, which can therefore implement any linear spatial filter. If left empty, flt_project will try to apply the ICA projection matrix, if present.'),...
    arg({'newchans','ChannelNames'}, [], [], 'New channel names. Cell array of new channel names, if known.','type','cellstr','shape','row'), ...
    arg({'subcomps','ComponentSubset'}, [], [], 'Component subset. List of component indices to which the result shall be restricted (or []).'), ...
    arg({'subchans','ChannelSubset'}, [], [], 'Channel subset. List of channel indices (or names) to which the data shall be restricted prior to application of the matrix.'));

append_online = {}; % this is a set of arguments that shall be appended during online use
if isempty(pmat) 
    if isfield(signal.etc,'amica')
        % project using AMICA weights
        subchans = signal.icachansind;
        for m=1:size(signal.etc.amica.W,3)
            tmp{m} = signal.etc.amica.W(:,:,m)*signal.etc.amica.S; end
        pmat = cat(1,tmp{:});        
    elseif isfield(signal,'icaweights') && ~isempty(signal.icaweights)
        % project using ICA weights
        subchans = signal.icachansind;        
        pmat = signal.icaweights*signal.icasphere;
    else
        pmat = eye(signal.nbchan);
    end
    % make sure that we know what the used projection matrix & channel subset was during online use
    append_online = {'pmat',pmat,'subchans',subchans};        
end

if ~isempty(subchans)
    subset = set_chanid(signal,subchans);
    if ~isequal(subset,1:signal.nbchan)
        signal = pop_select(signal,'channel',subset,'sorttrial','off'); end 
end

% project data
[C,S,T] = size(signal.data); %#ok<*NODEF>
signal.data = reshape(pmat*reshape(signal.data,C,[]),[],S,T); 
signal.nbchan = size(signal.data,1);

% rewrite chanlocs
if isempty(signal.urchanlocs)
    signal.urchanlocs = signal.chanlocs; end
if isempty(newchans)
    signal.chanlocs = struct('labels',cellfun(@num2str,num2cell(1:signal.nbchan,1),'UniformOutput',false));
elseif length(newchans) == signal.nbchan
    if isfield(newchans,'labels')
        signal.chanlocs = newchans;
    elseif iscellstr(newchans)
        signal.chanlocs = pop_chanedit(struct('labels',newchans),'lookup',[]);        
    elseif isnumeric(newchans)
        signal.chanlocs = signal.chanlocs(newchans);
    else
        error('The chanlocs format is unsupported.');
    end
else
    error('The number of provided channels does not match the data dimension.');
end

if ~isempty(subcomps)
    if isnumeric(subcomps) && any((subcomps(:)-floor(subcomps(:)) ~= 0)) && size(subcomps,2) == 2
        % components are given as fractional intervals
        subcomps = 1 + floor(subcomps*(signal.nbchan-1));
        tmp = [];
        for k=1:size(subcomps,1)
            tmp = [tmp subcomps(k,1):subcomps(k,2)]; end
        subset = set_chanid(signal,tmp);
        if ~isequal(subset,1:signal.nbchan)
            signal = pop_select(signal,'channel',subset,'sorttrial','off'); end
    else
        % components are given as indices
        subset = set_chanid(signal,subcomps);
        if ~isequal(subset,1:signal.nbchan)
            signal = pop_select(signal,'channel',subset,'sorttrial','off'); end
    end
end

exp_endfun('append_online',append_online);
