% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright © 2007 The Regents of the University of California
% Created by Javier Lopez-Calderon and Steven Luck
% Center for Mind and Brain, University of California, Davis,
% javlopez@ucdavis.edu, sjluck@ucdavis.edu
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function exportvaluesV2(ERP, values, binArray, chanArray, fname, dig, ncall, binlabop, formatout, mlabel, lat4mea)

if nargin<11
      lat4mea = []; % latencies for measurements given by the user
end
if nargin<10
      mlabel = ''; % label for measurement
end
if nargin<9
      formatout = 0; % 1 means "one erpset per line"; 0 means "one measurement per line".
end
if nargin<8
      binlabop = 0; % 0 means use "bin#" as a label for bin; 1 means use bind descr as a label
end
if nargin<7
      ncall = 1; % single call
end
if nargin<6
      dig = 3; % number of decimals
end
if nargin<5
      error('ERPLAB says: few input arguments for exportvaluesV2.m')
end

nbin  = length(binArray);
nchan = length(chanArray);

if isempty(ERP.chanlocs)
      for e=1:ERP.nchan
            chanlabels{e} = ['Ch' num2str(e)];
      end
else
      chanlabels = {ERP.chanlocs.labels};
end
if ncall==0
      error('ERPLAB says: errot at exportvaluesV2(). ncall must be any integer equal or greater than 1')
end
if ncall==1
      fprintf('Creating 1 text output file...\n');
      %disp(['An output file with your measuring work was create at <a href="matlab: open(''' fname ''')">' fname '</a>'])
      fid_values  = fopen(fname, 'w');
else
      fid_values  = fopen(fname, 'a'); %append
      fseek(fid_values, 0, 'eof');
end
disp(['An output file with your measuring work was create at <a href="matlab: open(''' fname ''')">' fname '</a>'])
VALUES  = values{1};

%
% Header
%
if ncall==1
      if formatout==0 % one erpset per line (WIDE)
            binline   = '';
            for b=1:nbin
                  for ch=1:nchan
                        if binlabop==0
                              binline = [binline sprintf('bin%g_%s', binArray(b), chanlabels{chanArray(ch)}) '\t' ];
                        else
                              binlabstr = regexprep(ERP.bindescr{binArray(b)},' ','_'); % replace whitespace(s)
                              binline = [binline sprintf('%s_%s', binlabstr, chanlabels{chanArray(ch)}) '\t' ];
                        end
                  end
            end
            
            binline = sprintf(binline);
            fprintf(fid_values,  '%s%s\n', ['ERPset' blanks(35)], binline);
            
      elseif formatout==1 % one measurement per line (LONG)
            headerline = {['ERPset' blanks(20)], [blanks(4) 'bin'],'chindex','chlabel', [blanks(dig+3) 'value']};
            
            
            
            if ~isempty(mlabel)
                  headerline = [headerline [blanks(10) 'mlabel']];
            end
            if ~isempty(lat4mea)
                  headerline = [headerline [blanks(10) 'worklat']];
            end
            
            lenheader = length(headerline);            
            formatoh = ['%s' repmat('%s\t',1,lenheader-2) '%s\n']; %s\t%s\t%s\t%s\n';
            fprintf(fid_values, formatoh, headerline{:});
      else
            error('ERPLAB says: errot at exportvaluesV2(). Unknown specified output format')
      end
end

%
% Values
%
if formatout==0 % one erpset per line (WIDE)
      
      fprintf(fid_values,  '%s', [ERP.erpname blanks(36-length(ERP.erpname))]);
      fstr1 = ['%.' num2str(dig) 'f'];
      
      for b=1:nbin
            for k=1:nchan
                  valstr =  sprintf(fstr1, VALUES(b,k));
                  blk = dig + 3 - length(valstr);
                  fprintf(fid_values,  '%s\t', [blanks(blk) valstr]);
            end
      end
      
      fprintf(fid_values,'\n');
      
elseif formatout==1 % one measurement per line (LONG)
      
      %         fprintf(fid_values,  '%s', [ERP.erpname blanks(16-length(ERP.erpname))]);
      fstr1 = ['%.' num2str(dig) 'f'];
      blk1 = 16 - length(mlabel);
      
      for b=1:nbin
            for k=1:nchan
                  valstr =  sprintf(fstr1, VALUES(b,k));
                  blk2 = dig + 3 - length(valstr);  
                                    
                  if isempty(lat4mea)
                        clat4meastr = '';
                  else
                        clat4mea = lat4mea{b,k};
                        
                        if length(clat4mea)==1
                              clat4meastr = ['[' num2str(clat4mea) ' ]'];
                        elseif length(clat4mea)==2
                              ss1 = sprintf('%.1f', clat4mea(1));
                              ls1 = length(ss1);
                              ss2 = sprintf('%.1f', clat4mea(2));
                              ls2 = length(ss2);
                              clat4meastr = ['[ ' ss1 blanks(7-ls1) ' ' ss2 blanks(7-ls2) ']'];                              
                        else
                              clat4meastr = 'error';                              
                        end
                  end
                  
                  blk3 = 20 - length(clat4meastr);
                  
                  if binlabop==0
                        binstr  = [num2str(binArray(b)) blanks(7-length(num2str(b)))];
                  else
                        binstr = regexprep(ERP.bindescr{binArray(b)},' ','_'); % replace whitespace(s)
                        binstr  = [binstr blanks(32-length(binstr))];
                  end
                  
                  chanstr = [num2str(chanArray(k)) blanks(7-length(num2str(k)))];
                  chanlabstr = [chanlabels{chanArray(k)} blanks(7-length(chanlabels{chanArray(k)}))];
                  fprintf(fid_values,  '%s %s\t%s\t%s\t%s\t%s\t%s\n', [ERP.erpname blanks(40-length(ERP.erpname))],...
                        binstr, chanstr, chanlabstr, [blanks(blk2) valstr], [blanks(blk1) mlabel], [blanks(blk3) clat4meastr]);
            end
      end
end

fclose(fid_values);