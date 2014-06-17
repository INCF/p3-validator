function results = bci_batchtrain(varargin)
% Apply bci_train to multiple data sets and approaches.
% Results = bci_batchtrain(Datasets,Approaches,PredictSets,LoadArguments,TrainArguments,SaveArguments,StoragePattern,ResultPattern,ProcessingOrder,ReuseExisting,DefaultName,ErrorHandler,ClusterEngine,ClusterPool,ClusterPolicy)
%
% This function is a convenience wrapper around bci_train and bci_predict. It can be used to apply
% an approach systematically to a range of data sets (e.g. those matching a file name pattern on disk).
% It can also be used to compare a series of approaches on one or more data sets.
%
% Essentially all of the functionality of bci_train and bci_predict is supported also in this function,
% so that the majority of offline analysis procedures can be applied with a single call to bci_batchtrain.
% A special feature of this function is that it stores the final results in a standard directory
% in a user-accessible form, and that it can optionally resume a cancelled batch computation by reusing
% existing results -- which is the recommended way to ensure that no data is lost in case of a crash.
%
% A streamlined approach to batch analysis involves first "curating" the raw source data sets in a script
% or by hand (e.g., ensuring that the desired markers are present or that the channel locations are 
% well-formed), then defining a series of approaches to be compared, and finally invoking bci_batchtrain
% on the directory containing the curated data sets.
% 
% In:
%   --- core arguments ---
%
%   Datasets : Data sets to process (train/cross-validate). Cell array of file names, file name 
%              patterns, or dataset structs.
%
%   Approaches : Approach(es) to use. Same format as in bci_train. If multiple approaches should be
%                applied, this may also be a struct, each of whose fields specifies another approach
%                to use (where the field name identifies the name of the respective approach as
%                used in this function's output).
%
%   PredictSets : Optional data sets on which to predict BCI outputs using bci_predict; must yield 
%                 one set for each set in Datasets (if specified in the same format as Datasets),
%                 or, if multiple  predict sets are given for each data set (e.g., multiple test
%                 sessions), must be a cell array of one cell array with test sets per each training
%                 set.
%
%   --- optional data pipeline customization ---
%
%   TargetMarkers : Target markers. List of types of those markers around which data shall be used
%                   for BCI calibration; each marker type encodes a different target class (i.e.
%                   desired output value) to be learned by the resulting BCI model. 
%                   
%                   This can be specified either as a cell array of marker-value pairs, in which
%                   case each marker type of BCI interest is associated with a particular BCI output 
%                   value (e.g., -1/+1), or as a cell array of marker types (in which case each 
%                   marker will be associated with its respective index as corresponding BCI output 
%                   value, while nested cell arrays are also allowed to group markers that correspond
%                   to the same output value). See help of set_targetmarkers for further explanation.
%
%   LoadArguments : Optional load arguments. Additional arguments to io_loadset - given as a cell
%                   array (e.g. {'channels',1:32}). (default: {})
%
%   TrainArguments : Optional training arguments. Additional arguments to bci_train - given as a
%                    cell array (e.g. {'eval_scheme', {'chron',5,5}}). (default: {})
%
%   PredictArguments : Optional prediction arguments. Arguments to bci_predict - given as a cell array.
%
%   SaveArguments : Optional save arguments. Additional arguments to io_save - given as a cell array.
%                   (default: {'-makedirs'})
%
%
%   --- optional output formatting ---
%
%   StudyTag : Tag of the performed study. May be used to identify/distinguish stored results on disk 
%              (see StoragePattern). Default: 'default'.
%
%   StoragePattern : Result storage pattern. This is a filename pattern with optional placeholders
%                    %caller (subtituted by the calling function''s name), %set (substituted by
%                    the respective file name or data set number that generated the result),
%                    %approach (substituted by the respective approach name), and %study (substituted
%                    by the StudyTag). Default: 'home:/batchtrain/%caller-%study/%approach-%set.mat' 
%                    Note that home:/ is the user's home directory; consider that the disk quota in 
%                    a user's home directory may be limited.
%
%   ResultPattern : Result output pattern. This is a MATLAB expression with optional placeholders
%                   %approach (substituted with the respective approach name), %num (substituted
%                   with the number of the respective data set) and %caller (substituted by the
%                   calling function's name). (default: 'results.%approach(%num) = ')
%
%   DefaultName : Default approach name. If only a single approach was given as a cell array rather
%                 than as a struct with subfields. (default: 'default')
%
%   --- optional computation organization ---
%
%   ProcessingOrder : Processing order. Either go through all sets first for one approach, then for
%                     the next, etc. (setsfirst), or go through all approaches for the first set,
%                     then for the next set, etc. (approachesfirst). Since some approaches may take
%                     orders of magnitude longer than others (perhaps unexpectedly), it is often the 
%                     best idea to specify aproaches in order of assumed running time, and use 
%                     the 'setsfirst' order. (default: 'setsfirst')
%
%   ReuseExisting: reuse existing results if the respective output files already exist on disk 
%                  (default: false)
%
%   ClusterResources : Cluster computation engine. If set to local, parallel processing is effectively 
%                      turned off. If set to global, the global BCILAB setting is used
%                      (tracking.parallel.engine), if set to BLS the BCILAB scheduler is used, and if
%                      set to ParallelComputingToolbox, the MATLAB PCT is used. Reference is for
%                      testing. (default: 'local')
%
%   ClusterPool : Cluster resource pool. If set to global, the global BCILAB setting 
%                 (tracking.parallel.pool) will be used. Otherwise, this is a cell array of
%                 hostnames (and optionally ports) of remote worker processes. (default: 'global')
%
%   --- miscellaneous ---
%
%   ErrorHandler : Error handler to use. Function handle or name that takes a struct as generated by
%                  lasterror(). (default: 'env_handleerror')
%
% Out:
%   Results: result structure, as constructed by the Result pattern, with a sub-struct for each data
%            set assigned to it. The sub-struct for each data set has the following fields:
%            'loss' : same as the loss output of bci_train
%            'model': same as the model output of bci_train
%            'stats': same as the stats output of bci_train
%
%            if PredictSets were specified, additional fields will be present:
%            'pred_loss'  : same as the loss output of bci_predict
%            'pred_stats' : same as the stats output of bci_predict
%            'pred_predictions' : same as the predictions output of bci_predict
%            'pred_targets': same as the targets output of bci_predict
%
% Notes:
%   Expect to be tempted to interrupt long-running computations. In this case, you will have to read
%   the data from disk -- so it is generally a good idea to not disable the StoragePattern.
%
% Examples:
%   first define some approach for subsequent use
%   myapproach = {'CSP', 'SignalProcessing',{'EpochExtraction',[0 3.5]}}};
%
%   % apply the given approach to all files named subject*.vhdr, in the directory studyX (assuming 
%   % that the events of interest are called 'S1' and 'S2').
%   results = bci_batchtrain('studyX/subject*.vhdr',myapproach,[],{'S1','S2'})
%
%   % apply the given approach to a list of file names
%   results = bci_batchtrain({'studyX/subject1.vhdr','studyX/subject2.vhdr','studyX/subject3.vhdr'},myapproach,[],{'S1','S2'})
%
%   % as before, but now using name-value arguments, and passing some additional io_loadset arguments (assuming we want to process only the first 32 channels)
%   results = bci_batchtrain('Datasets',{'studyX/subject1.vhdr','studyX/subject2.vhdr','studyX/subject3.vhdr'}, 'Approaches',myapproach, 'TargetMarkers',{'S1','S2'}, 'LoadArguments',{'channels',1:32})
%
%   % apply the given approach to a list of pre-loaded data sets
%   results = bci_batchtrain({myset1,myset2,myset3},myapproach,[],{'S1','S2'})
%
%   % apply the given approach to a list of pre-loaded data sets, but pass some special bci_train arguments to expedite processing using only a 3-fold cross-validation
%   results = bci_batchtrain({myset1,myset2,myset3},myapproach,[],{'S1','S2'},{'EvaluationScheme',{'chron',3,5}})
%
%   % as before, but using name-value arguments and disabling output into the home directory
%   results = bci_batchtrain('Datasets',{myset1,myset2,myset3}, 'Approaches',myapproach, 'TargetMarkers',{'S1','S2'}, 'TrainArguments',{'EvaluationScheme',{'chron',3,5}}, 'StoragePattern','')
%
%   % as before, but instead disabling the output as a MATLAB variable (perhaps to not exhaust the memory)
%   bci_batchtrain('Datasets',{myset1,myset2,myset3}, 'Approaches',myapproach, 'TargetMarkers',{'S1','S2'}, 'TrainArguments',{'EvaluationScheme',{'chron',3,5}}, 'ResultPattern','')
%
%   % again using 3 filenames, but this time also using 3 different approaches
%   myapproaches.simpleCSP = 'CSP';
%   myapproaches.advancedSpecCSP = 'SpecCSP';
%   myapproaches.experimentalCSP = {'CSP', 'Prediction',{'FeatureExtraction'{'PatternPairs',10},'MachineLearning',{'Learner',{'logreg',[],'variant','vb-ard'}}}};
%   results = bci_batchtrain({'studyX/subject1.vhdr','studyX/subject2.vhdr','studyX/subject3.vhdr'},myapproaches,[],{'S1','S2'})
%
% See also:
%   bci_train, bci_predict
% 
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2011-08-19

opts = arg_define(varargin, ...
    arg_norep({'datasets','Datasets','Data'},mandatory,[],'Data sets to process. Either a cell array of filenames, or a cell array of data sets (or collections thereof), or a path pattern string as understood by dir().'), ...
    arg_norep({'approaches','Approaches','Approach'},mandatory,[],'Approach(es) to use. Same format as in bci_train. If multiple approaches should be applied, this may also be a struct, each of whose fields specifies another approach to use (where the field name identifies the name of the respective approach as used in this function''s output).'), ...
    arg({'predictsets','PredictSets'},{},[],'Optional data sets for prediction. Must yield one set for each set in Datasets (if specified in the same format as Datasets), or, if multiple  predict sets are given for each data set (e.g., multiple test sessions), must be a cell array of one cell array with test sets per each entry in Datasets.'), ...
    arg({'markers','TargetMarkers'},{},[],'Target markers. List of types of those markers around which data shall be used for BCI calibration & prediction; each marker type encodes a different target class (i.e. desired output value) to be learned by the resulting BCI model. See help of bci_batchtrain or set_targetmarkers for further explanation.'), ...
    arg({'loadargs','LoadArguments'},{},[],'Optional load arguments. Arguments to io_loadset - given as a cell array.'), ...
    arg({'trainargs','TrainArguments'},{},[],'Optional training arguments. Arguments to bci_train - given as a cell array.'), ...
    arg({'predictargs','PredictArguments'},{},[],'Optional prediction arguments. Arguments to bci_predict - given as a cell array.'), ...
    arg({'saveargs','SaveArguments'},{'-makedirs'},[],'Optional save arguments. Optional save arguments. Additional arguments to io_save - given as a cell array.'), ...
    arg({'storepatt','StoragePattern'},'home:/.bcilab/batchtrain/%caller-%study/%approach-%set.mat',[], 'Result file name pattern. This is a filename pattern with optional placeholders caller (subtituted by the calling function''s name), %set (substituted by the respective file name or data set number that generated the result) and %approach (substituted by the respective approach name). If empty, no output is written to disk.'), ...
    arg({'resultpatt','ResultPattern'},'results.%approach(%num) = ',[], 'Result output pattern. This is a MATLAB expression with optional placeholders %approach (substituted with the respective approach name), %num (substituted with the number of the respective data set) and %caller (substituted by the calling function''s name).'), ...
    arg({'default','DefaultName'},'default',[],'Default approach name. If only a single approach was given as a cell array rather than as a struct with subfields.'), ...
    arg({'studytag','StudyTag'},'default',[],'Tag of the performed study. May be used to identify/distinguish stored results on disk (referred to in the StoragePattern).'), ...
    arg({'order','ProcessingOrder'},'setsfirst',{'setsfirst','approachesfirst'},'Processing order. Either go through all sets first for one approach, then for the next, etc. (setsfirst), or go through all approaches for the first set, then for the next set, etc. (approachesfirst). Since some approaches may take orders of magnitude longer than others, it is typically a good idea to specify aproaches in order of assumed running time, and use the setsfirst order.'), ...
    arg({'reuse','RetainExistingResults','ReuseExisting'},false,[],'Retain existing results. If the respective output files already exist on disk, they will be loaded and returned. Note: If you change an approach but fail to rename it, you may inadvertently get old results!'), ...
    arg({'loadonly','LoadOnly'},false,[],'Load only existing results. Do not (re-)compute missing results.'), ...
    arg({'handler','ErrorHandler'},'env_handleerror',[],'Error handler to use. Function handle or name that takes a struct as generated by lasterror().'), ...
    arg({'engine','ClusterResources','ClusterEngine'},'local',{'local','global','BLS','ParallelComputingToolbox','Reference'},'Cluster computation engine. If set to local, parallel processing is effectively turned off. If set to global, the global BCILAB setting is used (tracking.parallel.engine), if set to BLS the BCILAB scheduler is used, and if set to ParallelComputingToolbox, the MATLAB PCT is used. Reference is for testing.'), ...
    arg({'pool','ClusterPool'},'global',[],'Cluster resource pool. If set to global, the global BCILAB setting (tracking.parallel.pool) will be used. Otherwise, this is a cell array of hostnames (and optionally ports) of remote worker processes.'), ...
    arg({'policy','ClusterPolicy'},'global',[],'Cluster scheduling policy. If set to global, the global setting (tracking.parallel.policy) will be chosen. Otherwise, this may be the name of a custom scheduling policy function.'));

% --- reformat inputs ---

% sanitize datasets
if ischar(opts.datasets) || (isstruct(opts.datasets) && isscalar(opts.datasets))
    opts.datasets = {opts.datasets}; end
    
if ~iscell(opts.datasets)
    error('Datasets should be given as a cell array of structs and/or file names.');
else
    % for each data set...
    d = 1;
    while d <= length(opts.datasets)
        ds = opts.datasets{d};
        if ischar(ds)
            % given as a string
            if any(ds=='*')
                % ... with path pattern: expand
                infos = dir(ds);
                infos(strcmp({infos.name},'.') | strcmp({infos.name},'..')) = [];
                base = fileparts(ds);
                opts.datasets = [opts.datasets(1:d-1) cellfun(@(n)[base filesep n],{infos.name},'UniformOutput',false) opts.datasets(d+1:end)];
                ds = opts.datasets{d};
            end
            % try to load
            [dummy,setnames{d}] = fileparts(ds); %#ok<ASGLU>
            opts.datasets{d} = io_loadset(ds,opts.loadargs{:});
        elseif iscellstr(ds)
            % a cell array of file names: resolve via io_loadset
            for k=1:length(ds)
                ds{k} = io_loadset(ds{k},opts.loadargs{:}); end
            opts.datasets{d} = ds;
            setnames{d} = num2str(d);
        else
            % already a struct (or a cell array of collections): use a number as the setname
            setnames{d} = num2str(d);
        end
        d = d+1;
    end
end

if ~isempty(opts.predictsets)
    % sanitize predictsets
    if ischar(opts.predictsets) || (isstruct(opts.predictsets) && isscalar(opts.predictsets))
        opts.predictsets = {opts.predictsets}; end
    
    % for each (group of) predictset(s)...
    d = 1;
    while d <= length(opts.predictsets)
        ps = opts.predictsets{d};
        if ~iscell(ps)
            % handle non-cell entries
            if ischar(ps) && any(ps=='*')
                % ... given as a string with path pattern expression: first expand!
                infos = dir(ps);
                infos(strcmp({infos.name},'.') | strcmp({infos.name},'..')) = [];
                base = fileparts(ps);
                opts.predictsets = [opts.predictsets(1:d-1) cellfun(@(n)[base filesep n],{infos.name},'UniformOutput',false) opts.predictsets(d+1:end)];
                ps = opts.predictsets{d};
            end            
            % then wrap into a cell
            opts.predictsets{d} = {ps};
        end
        % now we are looking at cell arrays...
        c = 1;
        while c <= length(opts.predictsets{d})
            dps = opts.predictsets{d}{c};
            if ischar(dps)
                % given as a string
                if any(dps=='*')
                    % ... with path pattern: expand
                    infos = dir(dps);
                    infos(strcmp({infos.name},'.') | strcmp({infos.name},'..')) = [];
                    base = fileparts(dps);
                    opts.predictsets{d} = [opts.predictsets{d}(1:c-1) cellfun(@(n)[base filesep n],{infos.name},'UniformOutput',false) opts.predictsets{d}(c+1:end)];
                    dps = opts.predictsets{d}{c};
                end
                % try to load
                opts.predictsets{d}{c} = io_loadset(dps,opts.loadargs{:});
            end
            c = c+1;
        end
        d = d+1;
    end
    
    % now, PredictSets should a cell array of cells; check length
    if length(opts.predictsets) ~= length(opts.datasets)
        error('The number of PredictSets does not match the number of Datasets; there must be a 1:1 relationship between them.'); end

end

if iscellstr(opts.approaches) && all(cellfun(@isvarname,opts.approaches))
    try
        % if all approaches are valid variable names and exist in the base workspace, resolve them from there...
        apps = {};
        for a = 1:length(opts.approaches)
            apps.(opts.approaches{a}) = evalin('base',opts.approaches{a}); end
        opts.approaches = apps;
    catch
    end
end

if iscell(opts.approaches) || all(isfield(opts.approaches,{'paradigm','parameters'}))
    % A single approach is given
    if ~isvarname(opts.default)
        error('The DefaultName must comply with the syntax rules for MATLAB variable names.'); end
    opts.approaches = struct(opts.default,{opts.approaches});
elseif ~isstruct(opts.approaches) || numel(opts.approaches) > 1
    error('Approaches are given in an unsupported format.');
end

caller = char(hlp_getcaller);
if isempty(caller)
    caller = 'commandline'; end
opts.storepatt = strrep(strrep(opts.storepatt,'%caller',caller),'%study',opts.studytag);
opts.resultpatt = strrep(opts.resultpatt,'%caller',caller);
if ischar(opts.handler)
    opts.handler = str2func(opts.handler); end


% --- do processing ---

% make tasks
tasks = {};
switch opts.order
    case 'setsfirst'
        for appname = fieldnames(opts.approaches)'
            for d=1:length(opts.datasets)
                tasks{end+1} = {@do_processing,opts,d,appname{1},setnames}; end
        end
    case 'approachesfirst'
        for d=1:length(opts.datasets)
            for appname = fieldnames(opts.approaches)'
                tasks{end+1} = {@do_processing,opts,d,appname{1},setnames}; end
        end
    otherwise
        error('Unsupported processing order specified.');
end

% execute the tasks
outputs = par_schedule(tasks, 'engine',opts.engine,'pool',opts.pool,'policy',opts.policy);

% merge all outputs into the same results struct
try
    results = hlp_superimposedata(outputs{:});
catch e
    disp('Failed to merge outputs into the results data structure; returning a cell array of (unordered) per-job outputs; Traceback: ');
    env_handleerror(e);
    results = outputs;
end


% the actual processing function of bci_batchtrain
function results = do_processing(opts,d,appname,setnames)
try
    results = [];    
    storename = env_translatepath(strrep(strrep(opts.storepatt,'%set',setnames{d}),'%approach',appname));
    if opts.reuse && ~isempty(storename) && exist(storename,'file')
        disp(['Reusing existing result for approach "' appname '" on set "' setnames{d} '".']);
        load(storename);
    elseif ~opts.loadonly
        % train a model on the Dataset
        [res.loss,res.model,res.stats] = bci_train('data',opts.datasets{d}, 'approach',opts.approaches.(appname), 'markers',opts.markers, opts.trainargs{:});
        
        if ~isempty(opts.predictsets) && ~isempty(opts.predictsets{d})
            % optionally run bci_predict on the PredictSets
            for k=1:length(opts.predictsets{d})
                try
                    [res.pred_predictions{k},res.pred_loss(k),res.pred_stats{k},res.pred_targets{k}] = bci_predict('data',opts.predictsets{d}{k},'model',res.model, 'markers',opts.markers, opts.predictargs{:});
                catch e
                    [res.pred_predictions{k},res.pred_loss(k),res.pred_stats{k},res.pred_targets{k}] = deal([],NaN,struct(),[]);
                    disp(['Error computing predictions for set "' setnames{d} '", prediction set #' num2str(k) ' with approach "' appname '".']);
                    opts.handler(e);
                end
            end
            res.pred_loss = res.pred_loss';
        end
            
        % save results
        if ~isempty(storename)
            io_save(storename,opts.saveargs{:},'res'); end
    end
    if ~isempty(opts.resultpatt)
        eval([strrep(strrep(opts.resultpatt,'%num',num2str(d)),'%approach',appname) ' res;']); end
    try
        if isfield(res,'pred_loss')
            fprintf('%s@%s: train loss: %.4f, prediction loss: %.4f\n',appname,setnames{d},res.loss,res.pred_loss);
        else
            fprintf('%s@%s: train loss: %.4f\n',appname,setnames{d},res.loss);
        end
    catch
        disp('Could not display loss estimates.');
    end
catch e
    disp(['Error processing data set "' setnames{d} '" with approach "' appname '".']);
    opts.handler(e);
end
