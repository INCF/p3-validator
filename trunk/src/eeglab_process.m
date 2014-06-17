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

% Created from EEGLAB history file generated on the 28-Jul-2012
% Used to load BV data, extract epochs and to do basic FIR filtering
% 
%
% Inputs:
% see create_feature_vector for explanation
%
% Outputs
% averages - averaged EEG 
% EEG      - original EEG EEGLAB data
% ------------------------------------------------
function [averages, EEG] = eeglab_process(source_directory, source_file_name, class, preepoch, postepoch, min_fq, max_fq, Fs, Fsnew, wnd);

    % load BrainVision directory
    %EEG = pop_loadbv(source_directory, source_file_name, [1 831740], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19]);
    EEG = pop_loadbv(source_directory, source_file_name);
    %EEG = pop_biosig([source_directory, source_file_name]);
    EEG = eeg_checkset( EEG );

    % concat class into a marker name
    channel = ['S  ', num2str(class)]
    %channel = [class]

    % extract epochs with selected channel
    %EEG = pop_epoch( EEG, { channel  }, [-0.5           1], 'epochinfo', 'yes');
    EEG = pop_epoch( EEG, { channel  }, [preepoch   postepoch]);
    %EEG = pop_epoch( EEG);
    EEG = eeg_checkset( EEG );

    % remove baseline
    EEG = pop_rmbase( EEG, [preepoch * Fs    0]);
    EEG = eeg_checkset( EEG );

    % low-pass-filter the data 
    %EEG = pop_eegfilt( EEG, 0, max_fq);
    %EEG = eeg_checkset( EEG );
    %EEG = pop_eegfilt( EEG, min_fq, 0, (postepoch - preepoch) * Fs / 4);
    % EEG = pop_eegfilt( EEG, 0.01, 12, 16);
    %EEG = eeg_checkset( EEG );

    [EEG] = pop_resample( EEG, Fsnew);

    eeg_data = EEG.data;
    save('eeg_data', 'eeg_data');
    averages = utl_picktimes(EEG.data, Fsnew * wnd);
    save('averages', 'averages');
