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

% Test the trained LDA model on testing data, returns results
% containing accuracy, precision, and recall.
%
% 
%
% Inputs:
% test_features - M x N vector, where M is the dimension of the feature vector 
%                 and N is the number of features
% test_targets  - P x N vector, where P is the dimension of targets (typically a small
%                 integer) and N is the number of features
% model         - model returned by trainlda function
%
% Outputs:
% results - quality of classification on testing data presented in traditional meassures
function  [results] = testlda(test_features, test_targets, model);

    % change the targets vector into the format that is readable by BCILAB LDA
    targets = zeros(1, size(test_targets, 2));
    nontargetc = 1;
    targetc = 4;
    for (i = 1:length(targets))
        patternn = bin2dec( sprintf('%d',test_targets(:, i)));
        target(i) = patternn;
    end;

    % prediction itself
    classresults = ml_predictlda(test_features', model);
    classresults = classresults{1,2};

    % evaluate the results, and collect quality measures
    true_positives = 0;
    true_negatives = 0;
    false_positives = 0;
    false_negatives = 0;
    for (i = 1:length(targets))
        if (classresults(i, 1) > classresults(i, 2))
            % predicted nontarget
            if (target(i) == targetc)
                false_negatives = false_negatives + 1;
            elseif (target(i) == nontargetc)
                true_negatives = true_negatives + 1;
            end;
            else
            % predicted target
            if (target(i) == targetc)
                true_positives = true_positives + 1;
            elseif (target(i) == nontargetc)
                false_positives = false_positives + 1;
            end;
        end;
    end;

    % generate output structure
    results = struct;
    results.tp = true_positives;
    results.tn = true_negatives;
    results.fp = false_positives;
    results.fn = false_negatives;
    results.accuracy = (true_positives + true_negatives) / (true_positives + true_negatives + false_positives + false_negatives);
    results.precision = (true_positives) / (true_positives + false_positives);
    results.recall = (true_positives) / (true_positives + false_negatives);
    