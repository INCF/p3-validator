function [signal, time, chanlabels, pnts, nchan, serror] = loadtxterp(fullname, transpose, timex, elabel)

signal=[]; time=[]; chanlabels=''; pnts=[]; nchan=[];
serror = 0; % no errors
delimiter  = '\t';

if transpose == 0; % data matrix is point x elec  (normal, no transpose)
      if elabel==1
            nheaderlines = 1;
      else
            nheaderlines = 0;
      end
else   % data matrix is elec x points  (transposed. should be corrected)
      nheaderlines = 0;
end

% try
      values     = importdata(fullname, delimiter, nheaderlines);
      signal     = values.data;
      
      if transpose==1
            signal = signal'; % corrected
      end
      
      if timex==1
            time = signal(:,1);
            signal = signal(:,2:end);
      else
            time = [];
      end
      
      pnts  = size(signal,1);
      nchan = size(signal,2);
      
%       try
            if elabel==1
                  chanlabels = values.textdata;
                  if size(chanlabels,1)==1 && size(chanlabels,2)==1
%                         try
                              chanlabels=regexp(chanlabels,'.*?\s+', 'match');
                              chanlabels = [chanlabels{:}];
                              chanlabels=strtrim(chanlabels);
%                         catch
%                               fprintf('Oops...Please check ERP.chanlocs.labels. Is it fine?');
%                         end
                  end
                  if timex==1
                        chanlabels = chanlabels(~ismember(chanlabels,{'time'}));
                  end
            else
                  chanlabels = '';
            end
            
%       catch
%             chanlabels = '';
%       end
      
      if isempty(char(chanlabels))
            chanlabels = cell(1);
            for e=1:nchan
                  chanlabels{e} = ['Ch' num2str(e)];
            end
      end
% catch
%       serror = 1; % error found
% end