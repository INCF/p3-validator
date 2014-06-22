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

% training features selection
source_dir  = '..\training_dataset\';
source_file = 'set2.vhdr';

% testing features selection
test_dirs    = {'..\testing_dataset\104\Data'};
test_files   = {'LED_28_06_2012_104.vhdr'};



results = P300validate(source_dir, source_file, test_dirs, test_files)
