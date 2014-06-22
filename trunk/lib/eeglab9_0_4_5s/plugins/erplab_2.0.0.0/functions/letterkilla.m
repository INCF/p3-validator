% Remove white space from EEG alphanumeric event codes
% Deletes non-digit character from alphanumeric even codes.
% Converts remaining codes into numeric codes.
% Unconvertibles event codes (non digit info at all) will be renamed as -88
% 
% Usage
% 
% EEG = letterkilla(EEG)
%
% Input:
% EEG     - continous dataset with alphanumeric event codes
% 
% Output
% EEG     - continous dataset with numeric event codes
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

function EEG = letterkilla(EEG)

if nargin<1
        help letterkilla
        return
end
if isempty(EEG.data)
        msgboxText = 'letterkilla() cannot read an empty dataset!';
        title = 'ERPLAB: letterkilla() error';
        errordlg(msgboxText,title);
        return
end

nevent = length(EEG.event);

if nevent<1
        msgboxText = 'Event codes were not found!';
        title = 'ERPLAB: letterkilla() error';
        errordlg(msgboxText,title);
        return
end
if ~ischar(EEG.event(1).type)
        msgboxText = 'Event codes are numeric. So you do not need to run this tool.';
        title = 'ERPLAB: letterkilla() WARNING';
        errordlg(msgboxText,title);
        return
end

fprintf('\nletterkilla() is cleaning white spaces from your alphanumeric event codes (if any)...\n\n')
EEG = wspacekiller(EEG);

fprintf('\nletterkilla() is erasing any non-digit character from event from your alphanumeric event codes (if any)...\n')
fprintf('letterkilla() is creating numeric event codes from remaining information...\n')
fprintf('Alphanumeric codes without any digit character will be renamed as -88 (number)...\n')

for i=1:nevent
      
      codeaux = EEG.event(i).type;
      code    = regexprep(codeaux,'\D*','', 'ignorecase'); % deletes any non-digit character
      
      if isempty(code)
            code = -88;
      else
            code = str2num(code);
      end
      
      
      EEG.event(i).type =  code;
end

disp('COMPLETE!')