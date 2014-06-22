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

% Validates the P300 data using P300 classification method
%
% Input:
% training_dir - directory containing training Brainvision files
% training_file- vhdr. Brainvision file
% test_dirs    - directories containing testing Brainvision files
% test_files   - vhdr. Brainvsion files
% Output:
% results - for each testing dataset, save the calculated classification
% accuracy into this array
function [results] = P300validate(training_dir, training_file, test_dirs, test_files);

    % settings

    % epoch size
    full_size = 1024;

    % markers for classification
    markers = [2 4];

    % frequency filters
    min_fq = 0.1;
    max_fq = 8;

    % resampling
    Fs = 1000; %original sampling rate in Hz
    Fsnew = 100; %new sampling rate in Hz

    % picking a subset of EEG channels
    % C3 C4 P3 P4 Fz Cz Pz
    %channels = [ 6 7 8 17 18 19];
    %channels = [17 18 19];
    channels = [1:19]; %all

    % averaging
    averaging = 1;

    % epoch border settings
    preepoch = -0.5;
    postepoch = 1;

    % time picking windows
    wnd = [0.15 0.2; 0.2 0.25; 0.25 0.3; 0.3 0.35; 0.35 0.4; 0.4 0.45];
    %wnd = [0.2 0.25; 0.25 0.275; 0.275 0.3;  0.3 0.325; 0.325 0.35; 0.35 0.375; 0.375 0.4; 0.4 0.45];
    %wnd = [0.2 0.25; 0.25 0.3; 0.3 0.35; 0.35 0.4;0.4 0.45;0.45 0.5];
    %Blankertz
    %wnd = [0.115 0.135; 0.135 0.155; 0.155 0.195; 0.205 0.235; 0.285 0.325; 0.335 0.395; 0.495 0.535];
    %wnd = [0.25 0.35; 0.35 0.45];

    wnd = wnd - preepoch;
    features_size = length(channels) * length(wnd);

    [~, ~, out_features, out_targets] = create_feature_vector(markers, training_dir, training_file, features_size, full_size,  channels, averaging,  preepoch, postepoch, min_fq, max_fq, Fs, Fsnew, wnd);

    results = zeros(length(test_dirs), 1);

    for i = 1 : length(test_dirs)
        % load epochs
        [~, ~, out_featurestest, out_targetstest] = create_feature_vector(markers, test_dirs{i}, test_files{i}, features_size, full_size, channels, averaging, preepoch, postepoch, min_fq, max_fq, Fs, Fsnew, wnd);


        %remove eye blinks
        % clean = [];
        % threshold = 375;
        % blinking_example = load('artifact_sample.txt');
        % for (i = 1:size(out_features, 2))
        %     sig_conv = conv(out_features(:, i), blinking_example);
        %     [maxc, maxi] = max(sig_conv);
        %     corrs(i) = maxc;
        %     if (maxc < threshold)
        %       clean = [clean i];
        %     end;
        %      
        % end
        % out_features = out_features(:, clean);
        % out_targets  = out_targets (:, clean);


        % train and test the model
        [model] = trainlda(out_features, out_targets);
        [ldaresults] = testlda(out_featurestest, out_targetstest, model);
        results(i) = ldaresults.accuracy;
 
        % display the results - target vs nontarget features
        %noffeatures = size(out_featurestest, 2);
        %targetmean = mean(out_featurestest(:, out_targetstest(2, :) == 1),2);
        %nontargetmean = mean(out_featurestest(:, out_targetstest(2, :) == 0),2);
        %figure;
        %plot(targetmean);
        %hold on;
        %plot(nontargetmean, 'r');
    end
