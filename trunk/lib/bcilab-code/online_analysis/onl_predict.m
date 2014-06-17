function y = onl_predict(name,outfmt) %#ok<INUSD>
% Query a predictor given the current contents of the stream(s) referenced by it.
% Result = onl_predict(Name,Format)
%
% After a predictive model has been loaded successfully into the online system (which involves 
% opening and linking it to the necessary data streams), it can be "queried", i.e. its outputs can
% be requested, at any time and any rate, using this function.
%
% In:
%   Name : name of a predictor (under which is was previously created with onl_newpredictor)
%
%   Form     : the desired form of the prediction (see also ult_formatprediction), can be:       
%               * 'raw': the raw prediction, as defined by ml_predict (default)
%               * 'expectation': the output is the expected value (i.e., posterior mean) of the
%                                quantity to be predicted; can be multi-dimensional [1xD], but D
%                                equals in most cases 1
%               * 'distribution': the output is the probability distribution (discrete or
%                                 continuous) of the quantity to be predicted usually, this is a
%                                 discrete distribution - one probability value for every possible
%                                 target outcome [1xV] it can also be the parameters of a
%                                 parametric distribution (e.g., mean, variance) - yielding one
%                                 value for each parameter [DxP]
%               * 'mode': the mode [1xD], or most likely output value (only supported for discrete
%                         probability distributions)
%
% Out:
%   Result : Predictions of the selected model(s) w.r.t. to the most recent data.
%
% Example:
%   % obtain a prediction from a previously loaded model
%   output = onl_predict('mypredictor')
%
% See also:
%   onl_newpredictor, onl_newstream, onl_append
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-03

if nargin == 1
    outfmt = 'raw'; end %#ok<NASGU>

try
    % run predict_silenced() with the expression system disabled, is_online set to 1 (and console output suppressed)
    [output,y] = evalc('hlp_scope({''disable_expressions'',1,''is_online'',1},@predict_silenced,name,outfmt)'); %#ok<ASGLU>
catch e
    if ~exist('name','var')
        error('BCILAB:onl_predict:noname','The name of the predictor to use must be specified'); end
    if ~strcmp(e.identifier,'BCILAB:set_makepos:not_enough_data')
        disp('onl_predict() encountered an error; Traceback: ');
        env_handleerror(e); 
    end
    y = NaN;
end        



% compute the prediction for a given predictor
function y = predict_silenced(name,outfmt) %#ok<DEFNU>
try
    % get the predictor
    pred = evalin('base',name);
catch
    error(['A predictor with name ' name ' does not exist in the workspace.']);
end

% ensure that the prediction functions don't start parsing the arguments
pred.arg_direct = 1;

if ischar(pred.tracking.prediction_function)
    % prediction function given as a string
    if strncmp(pred.tracking.prediction_function,'Paradigm',8)
        % class reference: instantiate
        instance = eval(pred.tracking.prediction_function); %#ok<NASGU>
        pred.tracking.prediction_function = eval('@instance.predict');
    else
        % some other function
        pred.tracking.prediction_function = str2func(pred.tracking.prediction_function);
    end
end

% update all pipelines & obtain their buffers
buffers = cell(1,length(pred.pipelines));
buflen = zeros(1,length(pred.pipelines));
for p=1:length(pred.pipelines)
    pred.pipelines{p} = update_pipeline(pred.pipelines{p}, pred.tracking.prediction_window(p));
    buffers{p} = pred.pipelines{p}.buffer;
    buflen(p) = size(buffers{p}.data,2);
end

% if we have the requested amount of data in each buf (note: it could be that we have yet to see enough data)
if all(pred.tracking.prediction_window==buflen | pred.tracking.prediction_window==0)
    % invoke the prediction function appropriately
    if is_stateful(pred.tracking.prediction_function,[],[])
        [y,pred] = pred.tracking.prediction_function(struct('streams',{buffers}),pred);
    else
        y = pred.tracking.prediction_function(struct('streams',{buffers}),pred);
    end
    % format the results
    y = utl_formatprediction(y,outfmt);
else
    y = NaN;
end

% write back the updated predictor
assignin('base',name,pred);



% update the given filter pipeline from its source data, requesting a specified number of previous 
% samples (while 0 stands for "all new samples since the last request")
function p = update_pipeline(p,requested)
try
    % we need to keep track of our smax (xmax is automatically tracked properly)
    smax = p.buffer.smax;
catch
    smax = 0;
    % add potentially missing fields
    p.buffer = struct('data',{[]}, 'smax',{0});
    if ~isfield(p,'stateful')
        p.stateful = strcmp(char(p.head),'rawdata') || is_stateful(p.head); end
    if p.stateful && ~isfield(p,'state')
        p.state = []; end
    p.pipeline_mask = find(cellfun(@(x)all(isfield(x,{'head','parts'})),p.parts));
    p.israw = strcmp(char(p.head),'rawdata');
    if ~isfield(p,'subrequests')
        % this field stores the length of the buffer contents that is being requested by this stage 
        % from each lower pipeline
        p.subrequests = nan(1,length(p.pipeline_mask)); 
    elseif length(p.subrequests) ~= length(p.pipeline_mask)
        warn_once('BCILAB:onl_predict:inconsistent_pipeline','A filter pipeline node was encountered with a .subrequests field that does not match its sub-pipelines.');
        p.subrequests = nan(1,length(p.pipeline_mask)); 
    end
    % resolve any undetermined request lengths: if we are stateful, we will request 0, which means
    % "all new data", and if we are stateless, we request the amount of data that is being requested
    % from us (assuming that this pipeline stage is not a rate-changing stateless (i.e. epoch-based) 
    % filter). For any such filter to work, subrequests must have already been initialized properly
    % in utl_add_online.
    p.subrequests(isnan(p.subrequests)) = requested * ~p.stateful;
end

% update the input pipelines, and collect the arguments that we need in order to invoke the pipeline stage
args = p.parts;
% if we are a stateful pipeline, only new samples are requested (requested=0), otherwise the number of requested samples is passed on
for n = 1:length(p.pipeline_mask)
    k = p.pipeline_mask(n);
    % update dependent pipelines and take their buffers, rather than the structs themselves
    p.parts{k} = update_pipeline(p.parts{k},p.subrequests(n));
    args{k} = p.parts{k}.buffer;
    % if we are stateless, we must return whatever samples come from our buffer (possibly
    % transformed), and if there are multiple inputs, they must have the same sampling rate
    % therefore, our smax is that of any of our sub-pipelines
    if ~p.stateful
        smax = args{k}.smax; end
end

% update the buffer of the pipeline, given arguments
if p.israw
    % reading an input stream: update buffer given raw data
    try
        % get the stream from the base workspace
        stream = evalin('base',p.parts{1});
    catch e
        if strcmp(e.identifier,'MATLAB:badsubscript')
            error('BCILAB:onl_predict:improper_resolve','The raw data required by the predictor does not list the name of the needed source stream; this is likely a problem in onl_newpredictor');
        else
            error('BCILAB:onl_predict:stream_not_found',['The stream named ' p.parts{1} ' was not found in the base workspace.']);
        end
    end

    channels_to_get = p.parts{2};
    % by extracting only the new samples, rawdata behaves like a stateful pipeline stage
    samples_to_get = min(stream.buffer_len, stream.smax-p.buffer.smax);
    % copy buffer and read out .data field from circular .buffer field
    buf = stream;
    buf.data = stream.buffer(channels_to_get, 1+mod(stream.smax-samples_to_get:stream.smax-1,stream.buffer_len));    
    [buf.nbchan,buf.pnts,buf.trials] = size(buf.data);
    buf.chanlocs = buf.chanlocs(channels_to_get);
    buf.xmax = buf.xmin + buf.xmin + (buf.pnts-1)/buf.srate;

    % our smax is that of the raw buffer
    smax = buf.smax;
else
    buf = p.buffer;
    
    % regular filter stage: update buffer given inputs
    if p.stateful
        old_smax = buf.smax;
        % stateful filter function: we append & retrieve the state
        [buf,p.state] = p.head(args{:}, 'state',p.state);
        % smax is just counted up
        smax = old_smax + size(buf.data,2);
    else
        % stateless filter function: simple case;
        buf = p.head(args{:});
        % note: smax has already been deduced earlier
    end
end

if requested
    % if some other amount of data than just what's new has been requested...
    if requested ~= size(buf.data,2)
        if size(buf.data,2) < requested
            % stateful filters must concatenate the newly-produced outputs with the
            % data that they already have in the buffer from previous invocations
            if p.stateful
                if size(p.buffer.data,2) == requested
                    % we can do an in-place update without reallocations
                    % Note: if you get an error here, a filter (p.head) likely had returned different
                    %       numbers of channels across invocations.
                    buf.data = [p.buffer.data(:,size(buf.data,2)+1:end) buf.data];
                else
                    % append new samples & cut excess data
                    % Note: if you get an error here, a filter (p.head) likely had returned different
                    %       numbers of channels across invocations.
                    buf.data = [p.buffer.data buf.data];
                    if size(buf.data,2) > requested
                        buf.data = buf.data(:,end-requested+1:end); end
                end
            end
        else
            % cut excess data from the buffer
            buf.data = buf.data(:,end-requested+1:end);
        end
    end
    % update metadata
    buf.pnts = size(buf.data,2);
    buf.smax = smax;
    try
        buf.xmin = buf.xmax - (buf.pnts-1)/buf.srate;
    catch
        buf.xmax = buf.xmin + (buf.pnts-1)/buf.srate;
    end
end
% write back
p.buffer = buf;
