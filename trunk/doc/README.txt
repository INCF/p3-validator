Introduction / Quick start:
--------------------------------
The P300 validator contains multiple Matlab scripts that have a purpose of calculating quality measure (typically accuracy) for common odd-ball
paradigm P300 data. The scripts itself are located in the src directory. Note that for any user, two scripts are the most important:
- P300validate.m    - contains the starting function for the P300 validator
- run_offline_exp.m - is a Matlab script used for running the P300 validate function, serves as an example of usage
-------------------------------------------------------------------------------------------------------------------
Requirements:
--------------------------------
The P300 validator requires Matlab, BCILab, and EEGLAB. The required dependencies are located in the lib directory. The lib directory with its
subdirectories needs to be added to Matlab path before running the validator.
-------------------------------------------------------------------------------------------------------------------
Known issues:
--------------------------------
Matlab Out of Memory error: This issue is common for Windows 32-bit systems, and can be resolved by:
1) using smaller datasets for training and testing
2) following advice mentioned in http://www.mathworks.com/help/matlab/matlab_prog/resolving-out-of-memory-errors.html
-------------------------------------------------------------------------------------------------------------------