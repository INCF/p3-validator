function tf = par_haveupdate(current_file,reference_file)
% Return true if a code update is available.
% Result = par_haveupdate(CurrentFile,ReferenceFile);
%
% In:
%   CurrentFile : name of the file that is currently executing
%
%   ReferenceFile : name of a replacement file that is possibly newer than the CurrentFile
%
% Out:
%   Result : whether a newer ReferenceFile is available
%
% See also:
%   par_worker
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-08-26

tf = false;

try
    current_file = env_translatepath(current_file);
    reference_file = env_translatepath(reference_file);
catch
end

if ~exist(current_file,'file')
    fprintf('The currently executing code (%s) is non-existent; cannot check for updates.\n',current_file);
elseif exist(reference_file,'file')
        % reference file present: could potentially update: compare file dates
        ref_info = dir(reference_file);
        cur_info = dir(current_file);
        if isempty(ref_info)
            fprintf('No file info for ReferenceFile (%s) available. Cannot check for updates.\n',current_file);
            return;
        end
        if isempty(ref_info)
            fprintf('No file info for CurrentFile (%s) available. Cannot check for updates.\n',current_file);
            return;
        end
        % compare file dates
        tf = ref_info.datenum > cur_info.datenum;
    end
end
