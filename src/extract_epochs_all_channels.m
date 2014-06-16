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

% Extract epochs from EEG struct
% Input:
% EEG - EEGLAB data structure
% class - EEG stimuli markers without 'S '
% max_classes - limits the number of different classes
% channels - EEG channels to be extracted
% averaging - averaging factor

% Output:
% out_epochs - extracted epochs 
% out_targets - related target classes

function [out_epochs, out_targets] = extract_epochs_all_channels(EEG, class, max_classes, channels, averaging);

  no_epochs = EEG.trials;
  feat_length = length(EEG.data(1, :, 1));
  out_epochs = zeros(length(channels), feat_length, floor(no_epochs / averaging));

  out_targets = zeros(max_classes, floor(no_epochs / averaging));

  if nargin < 1 
      help extract_epochs;
      return;
  end;

  epoch_data = squeeze(EEG.data( channels,:,:));
  size(epoch_data)
  epoch_data = shuffle(epoch_data, 3);


  k = 1;
  averaged_epoch = zeros(length(channels), feat_length, 1);

  for i=1:no_epochs
    if (averaging == 1)
        out_epochs(:, :, i) = epoch_data(:, :, i);
        out_targets(class, i) = 1;
    elseif (mod(i, averaging) ~= 0)
        % fprintf('averaged_epoch\n')
        %size(averaged_epoch)
        %fprintf('epoch_data\n')
        %size(epoch_data)
        %averaged_epoch = averaged_epoch + epoch_data(:, :, i);
    else
        out_epochs(:, :, k) = averaged_epoch / averaging;
        out_targets(class, k) = 1;
        k = k + 1;
        averaged_epoch = zeros(length(channels), feat_length, 1);
    end;
  end  



