function [EEGOUT COMMANDS] = averaging(EEG, options)
%averaging() function for calculation of average using Dynamic Time Warping
% averaging() - Calculates Grand Average from current dataset or all open
% datasets
% Usage:
%      >> [EEGOUT COMMANDS] = averaging(EEG, options);
% Inputs:
%   EEG             - EEG.
%   options         - name/value pairs in struct, sent from GUI
% Outputs:
%   EEGOUT
%   COMMANDS
%
% Example
%    >> [EEGOUT COMMANDS] = averaging(EEG, 'display', 1);
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
        disp('Calculating Grand average for current dataset');
        disp(['Total ' num2str(num_channels*num_trials) ' trial items']);
        
        % For Grand average we need to concatenate all trials into one
        % row
        trials_text = '';
        for iter_i = 1:num_channels
            for iter_j = 1:num_trials
                trials_text = [trials_text ', EEG.data(' num2str(iter_i) ',:,' num2str(iter_j) ')'];
            end
        end
        
        command = ['trial_data = cat(1 ' trials_text '); '...
            'output.data = mean(trial_data);'...
            'output.trials = 1;'...
            'output.nbchan = 1;'...
            ];        
    otherwise,
        error(['Unrecognised argument, see help (' mfilename ')']);
end
% Commit the required operation
eval(command);



% Display image if required
if isfield(args,'data_display') && args.data_display == 1,
    
    if ~isfield(args,'figure_name'), args.figure_name = 'Figure'; end
    if ~isfield(args,'data_zero'), args.data_zero = 1; end
    if ~isfield(args,'invert_polarity'), args.invert_polarity = 1; end
    if ~isfield(args,'include_non_smoothed_data'), args.include_non_smoothed_data = 0; end
    if ~isfield(args,'smoothing'), args.smoothing = 1; end
    
    if args.smoothing > 1 && args.include_non_smoothed_data == 1,
       smoothed_data = smoothing(output.data, args.smoothing);
       
       myplot(args.figure_name, output.times, args.data_zero, ...
           args.invert_polarity, output.data, smoothed_data, ...
           'Smoothed average', 'Non-smoothed data');
    else
        myplot(args.figure_name, output.times, args.data_zero, ...
           args.invert_polarity,  smoothing(output.data, args.smoothing));        
    end
end


% Save new dataset
if isfield(args,'data_save') && args.data_save == 1,    
    if ~isfield(args,'data_name'), args.data_name = [EEG.setname ' - Grand Average']; end
    if ~isfield(args,'smoothing'), args.smoothing = 1; end      
      
    output.data = smoothing(output.data, args.smoothing);
    
    global ALLEEG;
    global CURRENTSET;
    
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, output, CURRENTSET, 'setname', args.data_name);
    
    fprintf('Data saved as new dataset: %s \n', args.data_name);
end


% Return averaged data only
if isfield(args,'data_return') && args.data_return == 1,    
    if ~isfield(args,'smoothing'), args.smoothing = 1; end   
    
    EEGOUT = smoothing(output.data, args.smoothing);
    return
end

EEGOUT = output;

end