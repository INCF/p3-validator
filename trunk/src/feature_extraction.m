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

% Extract features from epochs using the Windowed Means Paradigm 
%
% Input: 
% epochs - input epochs
% f_size - dimension of features
% full_size - dimension of original signal
%
% Output:
% epochs - output epochs
% features - calculated feature vectors
function [epochs, features] = feature_extraction(epochs, f_size, full_size);

    no_epochs = length(epochs(1, 1, :));
    features = zeros(f_size, no_epochs);


    for i=1:size(epochs, 3)
        features(:, i) = preprocessing(epochs(:, :, i),  f_size, full_size);
    end




