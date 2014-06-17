function run_readdataset(varargin)
% Receive (simulated) real-time data from a dataset.
% run_readdataset(MatlabStream,Dataset,UpdateFrequency)
%
% In:
%   MatlabStream : name of the stream to create
%
%   Dataset : dataset to use as source
%
%   UpdateFrequency : update frequency (default: 25)
%
% Examples:
%   % open a new input stream, and update it with data read in real time from an EEGLAB data set
%   run_readdataset('mystream',EEG)
%
%   % as before, but pass the arguments by name
%   run_readdataset('MatlabStream','mystream','Dataset',EEG)
%
%                               Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                               2010-11-19

% declare the name of this component (shown in the menu)
declare_properties('name','Dataset');

% read arguments...
arg_define(varargin, ...
    arg({'new_stream','MatlabStream'}, 'laststream',[],'New Stream to create. This is the name of the stream within the MATLAB environment.'), ...
    arg({'in_dataset','Dataset'}, 'lastdata',[],'Dataset to play back. This is the EEGLAB dataset that shall be played back in real time.','type','expression'), ...
    arg({'update_freq','UpdateFrequency'},25,[],'Update frequency. New data is polled at this rate, in Hz.'));

% evaluate dataset, if it's an expression
in_dataset = exp_eval_optimized(in_dataset);
in_dataset.starttime = tic;

% open a new online stream
onl_newstream(new_stream,rmfield(in_dataset,'data'));

% start a background reading job
onl_read_background(new_stream,@(stream)read_block(in_dataset,stream), update_freq);


% background block reader function
function block = read_block(in_dataset,stream)
% get current position
curpos = round(toc(in_dataset.starttime)*in_dataset.srate);
% get the next data block
block = in_dataset.data(:,1+mod(stream.smax : curpos-1,size(in_dataset.data,2)));
