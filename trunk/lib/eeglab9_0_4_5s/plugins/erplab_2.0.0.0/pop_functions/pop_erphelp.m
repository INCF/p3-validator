%
% Author: Javier Lopez-Calderon
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

function com = pop_erphelp

com = '';
fprintf('\nSearching for help file...\n');
mpath = path;
if ispc
    erpmpath1 = regexpi(mpath,'\;','split')';
else
    erpmpath1 = regexpi(mpath,'\:','split')';
end
erpmpath2 = regexpi(erpmpath1,'.*erplab.*','match')';
erpmpath2 = [erpmpath2{:}]';
erpmpath3 = regexpi(erpmpath2,'.*erplab_help$','match')';
erpmpath3 = char(unique([erpmpath3{:}]'));
if size(erpmpath3,1)>1
      fprintf('\n\nWARNING: You have a more than one ERPLAB folder added to your path.\n')
      fprintf('Please,keep just one version of ERPLAB in your Matlab path for a more accurate performance.\n')
      erpmpath3 = erpmpath3(end,:);
end
dir1 = fullfile(erpmpath3, 'erplab_manual.html');
fprintf('Help file found at %s\n', dir1);
% help eegplugin_erplab
if ispc
    winopen(dir1)
else
    dir1 = ['"file://' dir1 '"'];
    web(dir1, '-browser')
end
com = 'pop_erphelp';
return