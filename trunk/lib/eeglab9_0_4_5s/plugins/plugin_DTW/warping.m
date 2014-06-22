function [EEGOUT COMMANDS] = warping(EEG, options)
%averaging() function for calculation of average using Dynamic Time Warping
% averaging() - Calculates DTW with grand average data as a model 
% Usage:
%      >> [EEGOUT COMMANDS] = warping(EEG, options);
% Inputs:
%   EEG             - EEG.
%   options         - name/value pairs in struct, sent from GUI
% Outputs:
%   EEGOUT
%   COMMANDS
%
% Example
%    >> [EEGOUT COMMANDS] = dtw(EEG, 'display', 1);
%
% Author: Pavel Petrman, University of West Bohemia, Czech Republic,
% 17.5.2012

EEGOUT = []; % Something to return just in case
COMMANDS = [];

% Tranform parameter 'options' into struct (if possible and if needed)
if nargin > 1 && isstruct(options),
    args = options;
elseif nargin > 1 && ~isstruct(options),
    for index = 1:length(options)
        if iscell(options{index}) & ~iscell(options{index}{1})
            options{index} = { options{index} };
        end;
    end;
    if ~isempty( options )
        args = struct(options{:});
    else
        args = struct();
    end
else
    args = struct();
end


% Set default method: grand average
if ~isfield(args, 'type')
    args.type = 'current_dataset';
end


% Set default values and get important variable values
command = '';
output = EEG;
output.data = [];
output.trials = 1;
output.nbchan = 1;
output.epoch = output.epoch(1);
output.event = [];
output.eventdescription = [];
output.urevent = [];
output.saved = 'no';


% Prepare text of command for callback
switch args.type
    case 'current_dataset',
        output.pnts = EEG.pnts;
        output.xmin = EEG.xmin;
        output.xmax = EEG.xmax;
        output.srate = EEG.srate;
        output.times = EEG.times;
        
        [num_channels num_pts num_trials] = size(EEG.data);
        disp('Calculating DTW for current dataset');
        disp(['Total ' num2str(num_channels*num_trials) ' trial items']);
        
        % For DTWed average we need to concatenate all trials into one
        % row, get grand average
        
        if ~isfield(args,'smoothing'), args.smoothing = 1; end
        if ~isfield(args,'weights'), args.weights = [0.5 0.5]; end
        if ~isfield(args,'d_limit'), args.d_limit = 100; end
        if ~isfield(args,'p_limit'), args.p_limit = 1; end
        
        trials_text = '';
        for iter_i = 1:num_channels
            for iter_j = 1:num_trials
                trials_text = [trials_text ', dtw(model, '...
                    'EEG.data(' num2str(iter_i) ',:,' num2str(iter_j) '),'...
                    num2str(args.d_limit) ', ' num2str(args.p_limit) ', ' ...
                    num2str(args.smoothing) ', [' num2str(args.weights(1)) ...
                    ' ' num2str(args.weights(2)) '])'];
            end
        end
        

        command = ['callargs = struct(); callargs.data_return = 1; '...
            'callargs.smoothing = ' num2str(args.smoothing) ';'...
            'model = averaging(EEG, callargs);'...            
            'trial_data = cat(1 ' trials_text '); '...
            'output.data = mean(trial_data);'...
            'output.trials = 1;'...
            'output.nbchan = 1;'...
            ];        
    otherwise,
        error(['Unrecognised argument, see help (' mfilename ')']);
end
% Commit the required operation
disp('Calculating DTW...');
eval(command);
disp('DTW Complete.');


% Display image if required
if isfield(args,'data_display') && args.data_display == 1,
    
    if ~isfield(args,'figure_name'), args.figure_name = 'Figure'; end
    if ~isfield(args,'data_zero'), args.data_zero = 1; end
    if ~isfield(args,'invert_polarity'), args.invert_polarity = 1; end
    if ~isfield(args,'include_non_dtwed_data'), args.include_non_smoothed_data = 0; end
    
    if args.include_non_dtwed_data == 1,       
       
       myplot(args.figure_name, output.times, args.data_zero, ...
           args.invert_polarity, model, output.data, ...
           'Non-DTWed average','DTW average');
    else
        myplot(args.figure_name, output.times, args.data_zero, ...
           args.invert_polarity, output.data );        
    end
end


% Save new dataset
if isfield(args,'data_save') && args.data_save == 1,    
    if ~isfield(args,'data_name'), args.data_name = [EEG.setname ' - Grand Average']; end      
          
    global ALLEEG;
    global CURRENTSET;
    
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, output, CURRENTSET, 'setname', args.data_name);
    
    fprintf('Data saved as new dataset: %s \n', args.data_name);
end


EEGOUT = output;

end