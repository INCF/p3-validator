
% function asc2erp( ascfilename )

% fid_asc = fopen( ascfilename );
fid_asc = fopen( '/Tutorial/S1/Atest_uni_Frequent Category (Digit).txt' );
tdatas = textscan(fid_asc, '%[^\n]');
fclose(fid_asc);

% 
% 
% 
% go4 = 1;
% while go4
%       p0     = ftell(fid_asc);
%       tdatas = textscan(fid_asc, '%[^\n]',1);
%       ltoken = regexpi(char(tdatas{1}), 'nchans\s*(\d+)', 'tokens');
%       
%       if ~isempty(ltoken)
%             nchan    = str2num(char(ltoken{1}));
%             go4=0;
%             position = ftell(fid_asc);
%       end
% end
% 
% fseek(fid_asc, position, 'bof');
% i=1;
% j=1;
% chlabel = cell(1);
% 
% while i<=nchan
%       tdatas = textscan(fid_asc, '%[^\n]',1);
%       chtoken = regexpi(char(tdatas{1}), '(\d+)\s*"(\w+)"', 'tokens');
%       if ~isempty(chtoken)
%             chlabel{j} = chtoken{1}{2};
%             j=j+1;
%       end
%       i=i+1;
% end
% 
% i = 0;
% while i<=4
%       tdatas = textscan(fid_asc, '%[^\n]',1);
%       restoken = regexpi(char(tdatas{1}), 'resolution\s*(\d+)', 'tokens');
%       arstoken = regexpi(char(tdatas{1}), 'arslots\s*"(\w+)"', 'tokens');
%       digtoken = regexpi(char(tdatas{1}), 'digperiod\s*(\d+)', 'tokens');
%       caltoken = regexpi(char(tdatas{1}), 'calsize\s*(\d+)', 'tokens');
%       
%       if ~isempty(restoken)
%             resolution = str2num(char(restoken{1}));
%       end
%       if ~isempty(arstoken)
%             arslots    = arstoken{1};
%       end
%       if ~isempty(digtoken)
%             digperiod  = str2num(char(digtoken{1}));
%       end
%       if ~isempty(caltoken)
%             calsize    = str2num(char(caltoken{1}));
%       end
%       i=i+1;
% end
% 
% go4bin = 1;
% ibin = 0;
% while ~feof(fid_asc)
%       tdatas = textscan(fid_asc, '%[^\n]',1);
%       binnotoken = regexpi(char(tdatas{1}), '#\s*binno\s*(\d+)', 'tokens');
%       
%       if ~isempty(binnotoken)
%             binno = str2num(char(binnotoken{1}));
%             if binno==ibin
%                   fprintf('Bin %d was found succesfully.\n', ibin)
%                   ibin = ibin+1;
%                   k=1;
%                   param = {'bindesc\s*=','condesc','npoints','sampleperiod','presampling',...
%                         'sums','procfuncs','arejects'};
%                   while k<=8 && vv<100
%                         tdatas = textscan(fid_asc, '%[^\n]',1);
%                         paramtoken = regexpi(char(tdatas{1}), sprintf('', param{k}), 'tokens');
%                               if ~isempty(paramtoken)
%                               end
%                         
%                   end
%                   
%                   
%                   
%                   
%             else
%                   error('bin missed')
%             end
%       end
%       
% end
% 
% 
% fclose(fid_asc)
