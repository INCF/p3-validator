% This file is part of P300 Validator.
% 
%     The P300 validator is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     P300 Validator is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with P300 Validator.  If not, see <http://www.gnu.org/licenses/>.

% 
% Load BrainVision datasets, extract epochs and feature vectors, and connect all of them into one matrix
% 
%
% Inputs:
% classes       - defines stimuli marker number that will be extracted from ongoing brainvision eeg data 
% source_directory - defines source directory of BrainVision source files         
% source_file_name - defines .vhdr file to read from
% f_size         - defines the dimension of feature vector
% full_size         - defines the original dimension of input space
% channel         - EEG channel(s) to process into feature vectors
% averaging         - number of subsquent epochs to be averaged together
% preepoch      - pre-epoch interval in s
% postepoch      - post-epoch interval in s
% min_fq         - minimum frequency of the band-pass filter
% max_fq         - maximum frequency of the band-pass filter
% Fs             - original sampling frequency
% Fsnew          - new sampling frequency 
% wnd            - time windows of the algorithm, e.g. [0.2 0.3; 0.3 0.35]

% Outputs:
% origEEG - EEGLAB structure containing original data
% epochs  - contains the extracted epochs
% out_features - contains the features - [M x N] - M - dimension of features, N - number of features
% out_targets  - contains the targets  - [P x N] - P - target classes, N - number of features
function [origEEG, epochs, out_features, out_targets] = create_feature_vector(classes, source_directory, source_file_name, f_size, full_size, channel, averaging, preepoch, postepoch, min_fq, max_fq, Fs, Fsnew, wnd);


    % get a feature vector for every marker
    % and join them into NNToolBox training data
    for class = classes
        % extract epochs from vhdr file with selected markers
        [averages, origEEG] = eeglab_process(source_directory, source_file_name, class, preepoch, postepoch, min_fq, max_fq, Fs, Fsnew, wnd);
    
        EEG = origEEG;
        EEG.data = averages;
    
        % save epochs (and classification targets) to matlab matrix
        [epochs, targets] = extract_epochs_all_channels(EEG, class, max(classes), channel, averaging);
    
        % extract features from epochs
        [epochs, features] = feature_extraction(epochs, f_size, full_size);
    
        % join feature vectors throughout different markers
        if (exist('out_features') && exist('out_targets')) 
            sizeoffeatures = size(out_features, 2);
            features = features(:, 1:min(sizeoffeatures, size(features, 2)));
            targets  = targets(:, 1:min(sizeoffeatures, size(features, 2)));
            
            out_features = horzcat(out_features, features);
            out_targets  = horzcat(out_targets, targets);
        else
            out_features = features;
            out_targets = targets;    
        end
    end

    % shuffle everything
    [out_features, i, j] = shuffle(out_features, 2);
    out_targets = out_targets(:, i);