function com=pop_save(EEG,filename);

com='';
if nargin < 1 
    help pop_save;
    return;
end;

if nargin < 2
    [filename, filepath] = uiputfile('*', 'Output file');
    if length( filepath ) == 0 return; end;
   % filename = [ filepath filename ]
end; 
% remove extension if any
% -----------------------
posdot = find(filename == '.');
if ~isempty(posdot), filename = filename(1:posdot(end)-1); end;
no_epochs=EEG.trials 
for i=1:no_epochs
  ofname1=sprintf('%s_%02d_Fz.txt',filename,i);  
  ofname2=sprintf('%s_%02d_Pz.txt',filename,i);  
  ofname3=sprintf('%s_%02d_Cz.txt',filename,i);  
  dlmwrite(ofname1,EEG.data(17,:,i),'\n');
  dlmwrite(ofname2,EEG.data(18,:,i),'\n');
  dlmwrite(ofname3,EEG.data(19,:,i),'\n');
end  