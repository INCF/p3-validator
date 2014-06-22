Introduction / Quick start:
--------------------------------
The P300 validator contains multiple Matlab scripts that have a purpose of calculating quality measure (typically accuracy) for common odd-ball
paradigm P300 data. The scripts itself are located in the src directory. Note that for any user, two scripts are the most important:
- P300validate.m    - contains the starting function for the P300 validator
- run.m - is a Matlab script used for running the P300 validate function, serves as an example of usage

Run.m contains path of the training and testing datasets. It is possible to have one training and the unlimited number of testing datasets.
If you wish do test any other BrainVision datasets with D being the directory and F being the file name, the paths must be added like this:

test_dirs    = {'..\testing_dataset\104\Data', 'D'};
test_files   = {'LED_28_06_2012_104.vhdr', 'F'};


-------------------------------------------------------------------------------------------------------------------
Requirements:
--------------------------------
The P300 validator requires Matlab, BCILab, and EEGLAB. The required dependencies are located in the lib directory. The lib directory with its
subdirectories needs to be added to Matlab path before running the validator.

Because of the GitHub file size restrictions, the training data set could not be a part of this project. If you wish to use this training set
for validation, you can download it on the EEG/ERP Portal http://eegdatabase.kiv.zcu.cz/experiments-detail?4&DEFAULT_PARAM_ID=237 .
-------------------------------------------------------------------------------------------------------------------
Known issues:
--------------------------------
Matlab Out of Memory error: This issue is common for Windows 32-bit systems, and can be resolved by:
1) using smaller datasets for training and testing
2) following advice mentioned in http://www.mathworks.com/help/matlab/matlab_prog/resolving-out-of-memory-errors.html
-------------------------------------------------------------------------------------------------------------------