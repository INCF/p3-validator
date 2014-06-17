function context = utl_add_online(context)
% Internal. Post-step for exp_beginfun, adding an online expression to a dataset.
%
% This is a poststep (i.e. calculation that runs at the time of the exp_endfun call) to insert a
% .tracking.online_expression field into the data set that is returned by a filter stage; the
% online_expression is the one that will be evaluated online per chunk to realize this filter stage.
%
% This is the function that handles the 'set_online' and 'append_online' attributes.
%
% See also:
%   exp_beginfun, exp_endfun, utl_complete_model

% the mode is determined by the setting used in exp_beginfun and/or custom arguments to exp_endfun 
% (such as 'set_online'/'append_online')
mode = context.opts.set_online;

if strcmp(mode,'passthrough')
    
    % the function shall be skipped online: we effectively set as this online expression one of our
    % input signal's online expressions (the data sets among the filter arrguments are here viewed
    % as the input 'signals' during online operations). This is the default for the 'editing' setting 
    % in exp_begindef.
    online_expressions = {};
    for k=1:length(context.expression_posteval.parts)
        exp = context.expression_posteval.parts{k};
        if is_impure_expression(exp) && isfield(exp.tracking,'online_expression')
            online_expressions{end+1} = exp.tracking.online_expression; end %#ok<AGROW>
    end
    % there must be at least one signal among the inputs
    if isempty(online_expressions)
        error('BCILAB:exp_beginfun:no_skip','This stage cannot be skipped, since it does have not any input signal.');
    elseif length(online_expressions) > 1
        % and if there are multiple input signals, they must all be the same
        if ~all(cellfun(@(e)utl_same(e,online_expressions{1}), online_expressions(2:end)))
            error('BCILAB:exp_beginfun:no_skip','This stage cannot be skipped, since it has multiple different input signals.'); end
    end
    final_expression = online_expressions{1};
        
    if ~isempty(context.opts.append_online)
        error('BCILAB:exp_beginfun:cannot_append','You cannot append expressions to a filter that has been declared as ''editing'' (i.e. skipped). However, you can replace the entire expression for it by what you like to invoke online using the ''set_online'' attribute.'); end
    
elseif strcmp(mode,'inapplicable')

    % Generate an error when used online. This is the default for the 'offline' setting in exp_begindef.
    final_expression = struct('head',@error,'parts',{{'This function cannot be run online.'}});
    
else    
    % reproduce the original expression
    
    if strcmp(mode,'reproduce')
        % take the original expression directly as the online expression (this is the default for
        % 'filter' expressions, as specified in exp_settings)
        final_expression = context.expression_posteval;
    elseif isfield(mode,{'head','parts'})
        % completely replace the original expression by the set_online attribute
        final_expression = mode;
    elseif iscell(mode)
        % leave the function the same and override only the arguments (parts) by by the set_online
        % attribute
        final_expression = context.expression_posteval;
        final_expression.parts = mode;
    elseif isa(mode,'function_handle')
        % the given expression is just a function handle (i.e. a symbol)
        final_expression = mode;
    else
        % unknown format
        error('Unsupported ''set_online'' format.');
    end

    % append additional parameters, if requested
    if ~isempty(context.opts.append_online)
        if iscell(context.opts.append_online)
            final_expression.parts = [final_expression.parts context.opts.append_online];
        else
            error('The append_online attribute must be set to a cell array of parameters...');
        end
    end
    
    % the function will participate in online processing; we take the original expression (with
    % evaluated inputs) as the reproducing online expression
    if length(context.outargs) > 1 && isfield(context.ws_output_post,context.outargs{2})
        % if a second output is present and assigned, we treat it as a state output, and include it
        % in the final expression this will be picked up by the online system
        final_expression.state = context.ws_output_post.(context.outargs{2}); 
        
        % also, generally append 'state',state to the expression - for proper cross-validation behavior
        final_expression.parts = [final_expression.parts {'state' final_expression.state}];
    end
    
    % for all sub-arguments that have an online expression (i.e. data sets / signals), substitute 
    % their expression into the big online expression
    if isfield(final_expression,'parts')
        % this field lets us keep track of the window length expected from each respective input expression
        final_expression.subrequests = [];
        for k=1:length(final_expression.parts)
            exp = final_expression.parts{k};
            if isfield(exp,'tracking') && isfield(exp.tracking,'online_expression')
                if size(exp.data,3) > 1
                    % if this is epoched data, we record the window length expected from that stage
                    final_expression.subrequests(end+1) = size(exp.data,2);
                else
                    % if it is continuous data, we leave it open for later
                    final_expression.subrequests(end+1) = NaN;
                end
                final_expression.parts{k} = exp.tracking.online_expression;
            elseif all(isfield(exp,{'head','parts'})) && ~strcmp(char(exp.head),'rawdata')
                warning('BCILAB:utl_add_online:potential_issue','Note: the online expression for this filter depends on an unevaluated term, so that term''s the output sample count is not available. It will be assumed that this is not a rate-chaning epoch-based filter.');
                disp(['The term in question is: ' exp_fullform(exp)]);
                final_expression.subrequests(end+1) = NaN;
            end
        end
    end
    
    % last but not least, append an arg_direct,1 to the final expression
    final_expression.parts{end+1} = struct('arg_direct',{1});
end


% assign the expression to the .tracking.online_expression field of the first output (-to-be)
if isfield(context.ws_output_post.(context.outargs{1}),'tracking')
    context.ws_output_post.(context.outargs{1}).tracking.online_expression = final_expression; end
