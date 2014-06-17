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

% Trains LDA model on training data, returns the model for further classification
%
% 
%
% Inputs:
% out_features - M x N vector, where M is the dimension of the feature vector 
%                 and N is the number of features
% out_targets  - P x N vector, where P is the dimension of targets (typically a small
%                 integer) and N is the number of features
%
% Outputs:
% model - structure that contains the trained classifier
function  [model] = trainlda(out_features, out_targets);

    targets = zeros(1, size(out_targets, 2));
    for (i = 1:length(targets))
        targets(i) = bin2dec( sprintf('%d',out_targets(:, i)));
    end;

    Data = cell(2);
    Data = {out_features', targets'};

    %model = ml_train(Data,'lda');
    model = ml_trainlda(out_features', targets');
    %svm = svmlearn(out_features,targets);