function [ERP serror] = asc2erp(filename, pathname, transpose, timex, elabel, timeunit, fs, xlim)

ERP = builtERPstruct;
serror = 0;
if nargin<2
            error('ERPLAB says: error, filename and pathname are needed as inputs.')
end

nfile = length(filename);
npath = length(pathname);

if nfile>1 && npath==1
      pathname = cellstr(repmat(char(pathname),nfile,1))';
elseif nfile>1 && npath~=1 && npath~=nfile
      error('filename and pathname do not match')
elseif nfile==1 && npath~=1
      error('filename and pathname do not match')
end

bindata  = [];
% binerror = [];
bindescr = cell(1);
% accepted = [];

for i=1:nfile
      
      fname    = filename{i};
      pathn    = pathname{i};
      fullname = fullfile(pathn, fname);
      %       [signal, variance, chan_names, pnts, srate, xmin, xmax, nsweep] = loadavg2(fullname);
      [signal, time, chanlabels, pnts, serror] = loadtxterp(fullname, transpose, timex, elabel); %       chanlabels = cellstr(char(chan_names))';
      
      if serror==1
            ERP = builterpstruct; % empty struct
            return
      end
      if isempty(signal)
            ERP = builterpstruct; % empty struct
            serror =1;
            return
      end      
      if isempty(fs) && ~isempty(xlim)
            if timex==1
                  speriod = mode(abs(diff(time)));
                  if timeunit==1E-3
                        fs = round(1/(speriod/1000));
                  else
                        fs = round(1/speriod);
                  end
            else
                  xmin  = xlim(1); %in msec
                  xmax  = xlim(2); %in msec
                  time  = single(linspace(xmin,xmax,pnts)); % in msec
                  speriod = mode(abs(diff(time)));
                  fs = round(1/(speriod/1000));
                  timeunit = 1E-3; % in msec
            end
      elseif (~isempty(fs) && isempty(xlim)) %|| isempty(fs) && isempty(xlim)
            if timex==0
                  error('ERPLAB says: There is not way to estimate the time values for this file')
            end
      elseif isempty(fs) && isempty(xlim)
            if timex==1
                  speriod = mode(abs(diff(time)));
                  if timeunit==1E-3
                        fs = round(1/(speriod/1000));
                        %xlim  = [min(time) max(time)]/1000; % to sec                        
                  else
                        fs = round(1/speriod);
                        %xlim  = [min(time) max(time)]; % in sec
                  end
            else
                  error('ERPLAB says: There is not way to estimate the time values for this file')
            end
      else
            if timex==1
                  est_speriod = mode(abs(diff(time)));
                  if timeunit==1E-3
                        est_fs = round(1/(est_speriod/1000));
                  else
                        est_fs = round(1/est_speriod);
                  end
                  
                  srdiff = abs((fs-est_fs)/est_fs);
                  if srdiff>0 && srdiff<=0.1
                        msgwrng = 'WARNING: The specified sample rate is %.1f off from the computed sample rate.\n';
                        %try cprintf([1 0.52 0.2], '\n%s\n\n', sprintf(msgwrng));catch,fprintf('%\ns\n\n', sprintf(msgwrng));end ;
                        warningatcw(sprintf(msgwrng,srdiff), [1 0.52 0.2])
                  elseif srdiff>0.1
                        serror =2; % error greater that 10%
                        return
                  end
            else
                  xmin  = xlim(1); %in msec
                  xmax  = xlim(2); %in msec
                  time  = single(linspace(xmin,xmax,pnts)); % in msec
                  timeunit = 1E-3; % in msec                  
            end            
      end
      
      %
      % Correct for exact zero time at time-locked event code
      %
      zerox = min(abs(time));
      time  = time - zerox; % creates an exact zero for time-locked event
      if timeunit==1E-3
            xlim  = [min(time) max(time)]/1000; % to sec
      else
            xlim  = [min(time) max(time)]; % to sec
      end
      
      srate = fs;
      xmin  = xlim(1);
      xmax  = xlim(2);
      
      if i>1
            if ismember(0, strcmpi(chanlabels, auxchlab))
                  error('chan label error!')
            end
            if srate~=auxsrate
                  error('rate error!')
            end
            if xmin~=auxxmin
                  error('xmin error!!!')
            end
            if xmax~=auxxmax
                  error('xmax error!!!')
            end
      end
      
      auxchlab = chanlabels;
      auxsrate = srate;
      auxxmin  = xmin;
      auxxmax  = xmax;
      
      if i>1
            if (size(signal,1)~=size(bindata,1)) || (size(signal,2)~=size(bindata,2))
                  error('dim data!!!')
            end
            %if (size(variance,1)~=size(binerror,1)) || (size(variance,2)~=size(binerror,2))
            %      error('dim error!!!')
            %end
      end
      
      bindata  = cat(3, bindata, signal') ;
      
%       if isempty(variance)
%             variance = zeros(size(signal));
%       else
%             if ischar(variance)
%                   variance = zeros(size(signal));
%             end
%       end
%       
%       binerror = cat(3, binerror, variance);
      bindescr{i} = strrep(fname, '.txt', ''); 
%       accepted = [accepted nsweep];
end

% if nnz(binerror)<numel(bindata)
%       binerror = [];
% else
%       binerror = sqrt(binerror);
% end

ERP = builtERPstruct;

% ERP.erpname   =
% ERP.filename  =
% ERP.filepath  =
% ERP.workfiles =
% ERP.subject   =
nchan = size(bindata, 1);
ERP.nchan     = nchan;
nbin = size(bindata, 3);
ERP.nbin      = nbin;
ERP.pnts      = size(bindata, 2);
ERP.srate     = srate;
ERP.xmin      = xmin;
ERP.xmax      = xmax;
xminms        = round(xmin*1000);
xmaxms        = round(xmax*1000);
t = linspace(xminms, xmaxms, pnts);
indx = find(t>0,1);
times = t-t(indx);
ERP.times     =  times;
ERP.bindata   = bindata;
ERP.binerror  = []; % temporary...

if isempty(chanlabels)
      for e=1:nchan
            ERP.chanlocs(e).labels = ['Ch' num2str(e)];
      end
else
      chmin = min(nchan,length(chanlabels));
      [ERP.chanlocs(1:chmin).labels] = chanlabels{1:chmin};
end

ERP.ntrials.accepted = zeros(1, nbin)+100; % temporary
ERP.ntrials.rejected = zeros(1, nbin);
ERP.ntrials.invalid  = zeros(1, nbin);
ERP.ntrials.arflags  = zeros(nbin,8);

%     accepted: []
%     rejected: []
%      invalid: []
%      arflags: [0x8 double]

ERP.isfilt    = 0;
%ERP.chanlocs  =
%ERP.ref       =

ERP.bindescr  = bindescr;