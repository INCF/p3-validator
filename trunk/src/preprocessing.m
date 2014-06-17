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

% Transform an ERP epoch into feature using selected feature
% extraction method

% epoch - contains e.g. [Fz, Cz, Pz] x the samples defining the ERP epoch
% f_size - size of the feature vector
% full_size - size of the original input epoch
function  [features] = preprocessing(epoch, f_size, full_size);

    def_size = full_size;
    starting_size = 477;
    features = reshape(epoch, 1, size(epoch, 1) * size(epoch, 2));
    features = features / norm(features);



