% Remove white space from EEG alphanumeric event codes
% 
% Usage
% 
% EEG = wspacekiller(EEG)
%
% Input:
% EEG     - continous dataset with alphanumeric event codes
% 
% Output
% EEG     - continous dataset with white-space characters removed from alphanumeric event codes
%
%
%
% Author: Javier Lopez-Calderon
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% January 25th, 2011
%
% Thanks to Erik St Louis and Lucas Dueffert for their valuable feedbacks.
%

function EEG = wspacekiller(EEG)

if nargin<1
        help wspacekiller
        return
end
if isempty(EEG.data)
        msgboxText = 'wspacekiller() cannot read an empty dataset!';
        title = 'ERPLAB: wspacekiller() error';
        errordlg(msgboxText,title);
        return
end
nevent = length(EEG.event);
if nevent<1
        msgboxText = 'Event codes were not found!';
        title = 'ERPLAB: wspacekiller() error';
        errordlg(msgboxText,title);
        return
end
if ~ischar(EEG.event(1).type)
        msgboxText = 'Event codes are numeric. So wspacekiller() was not applied.';
        fprintf('\nNOTE: %s\n\n', msgboxText)
        return
end
fprintf('wspacekiller() is cleaning white spaces from your alphanumeric event codes (if any)...\n');
for i=1:nevent
        EEG.event(i).type =  strrep(strtrim(EEG.event(i).type),' ','');
end
disp('COMPLETE!')