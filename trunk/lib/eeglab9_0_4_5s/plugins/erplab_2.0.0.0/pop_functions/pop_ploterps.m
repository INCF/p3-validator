% pop_ploterps
% 
% PURPOSE  :	Plot ERP datasets
% 
% FORMAT   :
% 
% >> pop_ploterps(ERP, binArray, chanArray, options)
% 
% EXAMPLE  :
% 
% >> pop_ploterps(ERP)   -GUI will appear
% 
% or
% 
% >> pop_ploterps( ERP,1:3,1:16 , 'Axsize', [ 0.05 0.08], 'BinNum', 
% 'on', 'Blc', 'pre', 'Box', [ 4 4], 'ChLabel', 'on', 'FontSizeChan', 10, 
% 'FontSizeLeg', 10, 'LegPos', 'bottom', 'LineWidth', 1, 'Style', 'Matlab', 
% 'xscale', [ -200.0 798.0 -100:170:750 ], 'YDir', 'normal', 'yscale', 
% [ -10.0 10.0 -10:5:10 ] );                                                                                                                                                                                                                                      
% 
% INPUTS   :
% 
% ERP 				- input dataset
% binArray			- index(es) of bin(s) to plot( 1 2 3 ...)
% chanArray 			- index(es) of channel(s) to plot ( 1 2 3 ...)
% 
% options:
% 
% blcorr			- string or numeric interval for baseline correction
%                               reference window: 'no','pre','post','all', or a 
%                                specific time window, for instance [-100 0]
% xscale			- time window to plot: [t1 t2]. e.g. [-200 800]
% yscale			- amplitude scale to plot: [a1 a2]. e.g. [-5 10]
% linewidth                     - waveform line width
% isiy                           - string. 'yes'="Y" axis is inverted, 'no'=�Y� axis 
%                                not inverted
% fschan			- font size for channel labels
% fslege			- font size for legends
% meap                           - string. 'yes'=toolbar on, 'no'=toolbar off and "zero 
%                               x axis plotting"
% errorstd                      - string. 'yes'=create a Standard Deviation Structure 
%                               of your ERP, 'no'= do nothing.
% box 				- distribution of plotting boxes in rows x columns. 
%                               Important Note: rows*columns >= length(chanArray)
% 
% OUTPUTS  :
% 
% Figure on the screen
%
%
% GUI: ploterpGUI.m ; SUBROUTINE: ploterps.m
% 
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright � 2007 The Regents of the University of California
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

function [erpcom] = pop_ploterps(ERP, binArray, chanArray, varargin)

erpcom = '';

if nargin < 1
      help pop_ploterps
      return
end
if ~isfield(ERP,'bindata') %(ERP.bindata)
      msgboxText{1} =  'Error: cannot plot an empty ERP dataset';
      title_msg = 'ERPLAB: pop_ploterps() error:';
      errorfound(msgboxText, title_msg);
      return
end
if nargin==1  %with GUI
      countp = 0;
      while 1            
            plotset   = ploterpGUI;   % call GUI for plotting            
            if isempty(plotset.ptime)
                  disp('User selected Cancel')
                  return                  
            elseif strcmpi(plotset.ptime,'pdf')                  
                  erpcom2 = pop_fig2pdf;                  
                  if countp>0
                        disp('pop_fig2pdf was called')
                  else
                        disp('WARNING: Matlab figure(s) might have been generated during a previous round....')
                  end
                  erpcom = [erpcom ' ' erpcom2];
                  return                  
            elseif strcmpi(plotset.ptime,'scalp')
                  disp('User called pop_scalplot()')
                  return
            end            
            if plotset.ptime.istopo==1
                  %
                  % Searching channel location
                  %
                  if isfield(ERP.chanlocs, 'theta')
                        ERP = borrowchanloc(ERP);
                  else
                        question = cell(1);
                        question = ['This averaged ERP has not channel location info.\n'...
                                    'Would you like to load it now?'];
                        title_msg   = 'ERPLAB: Channel location';
                        button   = askquest(sprintf(question), title_msg);
                        
                        if ~strcmpi(button,'yes')
                              disp('User selected Cancel')
                              return
                        else
                              ERP = borrowchanloc(ERP);
                        end
                  end
            end

            plotset.ptime.binArray  = plotset.ptime.binArray(plotset.ptime.binArray<=ERP.nbin);
            plotset.ptime.chanArray = plotset.ptime.chanArray(plotset.ptime.chanArray<=ERP.nchan);
            plotset.ptime.chanArray_MGFP = plotset.ptime.chanArray_MGFP(plotset.ptime.chanArray_MGFP<=ERP.nchan);

            if isempty(plotset.ptime.binArray)
                    msgboxText =  'Invalid bin index(ices)';
                    title_msg  = 'ERPLAB: pop_ploterps() invalid info:';
                    errorfound(msgboxText, title_msg);
                    return
            end
            if isempty(plotset.ptime.chanArray)
                    msgboxText =  'Specified channel(s) did not have a valid channel location.';
                    title_msg  = 'ERPLAB: pop_ploterps() invalid info:';
                    errorfound(msgboxText, title_msg);
                    return
            end
            %if plotset.ptime.xscale(1) < ERP.xmin*1000
            %        plotset.ptime.xscale(1) = ERP.xmin*1000;
            %end
            %if plotset.ptime.xscale(2) > ERP.xmax*1000
            %        plotset.ptime.xscale(2) = ERP.xmax*1000;
            %end
            if ~isfield(plotset.ptime, 'posfig')
                  plotset.ptime.posfig = [];
            end
            
            findplot = findobj('Tag','Plotting_ERP');
            
            if ~isempty(findplot)
                  gofig = 1;
                  while gofig>0 && gofig<= length(findplot)
                        lastfig = figure(findplot(gofig));
                        posfx   = get(lastfig,'Position');
                        
                        if posfx(3)>=1 && posfx(4)>=1
                              plotset.ptime.posfig = [posfx(1)+10 posfx(2)-15 posfx(3) posfx(4) ];
                              gofig = 0;
                        else
                              gofig = gofig + 1;
                              
                        end
                  end
            end
            
            assignin('base','plotset', plotset);
            
            binArray      = plotset.ptime.binArray;
            chanArray     = plotset.ptime.chanArray;
            ichMGFP       = plotset.ptime.chanArray_MGFP;
            iblcorr       = plotset.ptime.blcorr;
            ixscale       = plotset.ptime.xscale;
            iyscale       = plotset.ptime.yscale;
            ilinewidth    = plotset.ptime.linewidth;
            iisiy         = plotset.ptime.isiy;
            ifschan       = plotset.ptime.fschan;
            ifslege       = plotset.ptime.fslege;
            imeap         = plotset.ptime.meap;
            ierrorstd     = plotset.ptime.errorstd;
            ibox          = plotset.ptime.box;
            %icounterwin   = plotset.ptime.counterwin;
            iholdch       = plotset.ptime.holdch;
            iyauto        = plotset.ptime.yauto;
            ibinleg       = plotset.ptime.binleg;            
            ichanleg      = plotset.ptime.chanleg; % @@@@@@@@@@@@@@@@@@@
            %iisMGFP       = plotset.ptime.isMGFP;
            ilegepos      = plotset.ptime.legepos;
            iistopo       = plotset.ptime.istopo;
            ismaxim       = plotset.ptime.ismaxim;
            posfig        = plotset.ptime.posfig;
            axsize        = plotset.ptime.axsize;
            minorticks    = plotset.ptime.minorticks;
            
            if iyauto==1
                  rAutoYlim = 'on';
            else
                  rAutoYlim = 'off';
            end            
            if ibinleg==1
                  rBinNum = 'on';
            else
                  rBinNum = 'off';
            end             
            if ichanleg==1 % @@@@@@@@@@
                  rchanlabel = 'on'; % show ch label
            else
                  rchanlabel = 'off'; % show ch number
            end         
            
            if iholdch==1
                  rHoldCh = 'on';
            else
                  rHoldCh = 'off';
            end
            if ilegepos==1
                  rLegPos = 'bottom';
            elseif ilegepos==2
                  rLegPos = 'right';
            else
                  rLegPos = 'external';
            end            
            if ierrorstd==1
                rStd = 'on';
            elseif ierrorstd>1
                rStd = num2str(ierrorstd); % for more than 1 stdev
            else
                rStd = 'off';
            end                              
            if iistopo == 0;
                  if imeap==1
                        rStyle = 'Matlab';
                  else
                        rStyle = 'ERP';
                  end
            else
                  rStyle = 'Topo';
            end            
            if iisiy==1
                  rYDir = 'reverse';
            else
                  rYDir = 'normal';
            end
            if ismaxim==1
                  rismaxim = 'on';
            else
                  rismaxim = 'off';
            end
            
            if minorticks(1)
                  mtxstr = 'on';
            else
                  mtxstr = 'off';
            end
            
            if minorticks(2)
                  mtystr = 'on';
            else
                  mtystr = 'off';
            end
            
            erpcom = pop_ploterps(ERP, binArray, chanArray, 'AutoYlim',rAutoYlim,'BinNum',rBinNum,'Blc',iblcorr,'Box',ibox,...
                  'FontSizeChan',ifschan,'FontSizeLeg',ifslege, 'HoldCh',rHoldCh,'LegPos',rLegPos,...
                  'LineWidth',ilinewidth,'Mgfp',ichMGFP,'Std',rStd,'Style',rStyle,'xscale',ixscale,'YDir',rYDir,...
                  'yscale',iyscale, 'Maximize', rismaxim, 'Position', posfig, 'axsize', axsize, 'ChLabel', rchanlabel,...
                  'MinorTicksX', mtxstr ,'MinorTicksY', mtystr); % @@@@@@@
            pause(0.1)
            countp = countp + 1;
      end      
      return      
else
      aa = round(sqrt(ERP.nchan));
      boxd = [aa+1 aa];
      
      p = inputParser;
      p.FunctionName  = mfilename;
      p.CaseSensitive = false;
      p.addRequired('ERP', @isstruct);
      p.addRequired('binArray', @isnumeric);
      p.addRequired('chanArray', @isnumeric);
      p.addParamValue('Mgfp', [], @isnumeric);
      p.addParamValue('Blc', 'none', @ischar);
      p.addParamValue('xscale', [round(ERP.xmin*1000) round(ERP.xmax*1000)], @isnumeric);
      p.addParamValue('yscale', [-10 10], @isnumeric);
      p.addParamValue('LineWidth', 1, @isnumeric);
      p.addParamValue('YDir', 'normal', @ischar); % normal | reverse
      p.addParamValue('FontSizeChan', 10, @isnumeric);
      p.addParamValue('FontSizeLeg', 10, @isnumeric);
      p.addParamValue('Style', 'Matlab', @ischar); %Matlab | ERP | Topo
      p.addParamValue('Std', 'off', @ischar);
      p.addParamValue('Box', boxd, @isnumeric);
      p.addParamValue('HoldCh', 'off', @ischar);
      p.addParamValue('AutoYlim', 'on', @ischar);
      p.addParamValue('BinNum', 'off', @ischar);      
      p.addParamValue('ChLabel', 'on', @ischar);       
      p.addParamValue('LegPos', 'bottom', @ischar); % right | external
      p.addParamValue('Maximize', 'off', @ischar); % off | on
      p.addParamValue('Position', [], @isnumeric); % off | on
      p.addParamValue('Axsize', [], @isnumeric); % size ([w h] ) for each channel when topoplot is being used.
      p.addParamValue('MinorTicksX', 'off', @ischar); % off | on
      p.addParamValue('MinorTicksY', 'off', @ischar); % off | on
      
      p.parse(ERP, binArray, chanArray, varargin{:});
      
      if max(chanArray)>ERP.nchan
              msgboxText =  ['Channel(s) %g do(es) not exist within this erpset.\n'...
                      'Please, check your channel list'];
              title_msg = 'ERPLAB: pop_ploterps() invalid channel index';
              errorfound(sprintf(msgboxText, chanArray(chanArray>ERP.nchan)), title_msg);
              return
      end
      if min(chanArray)<1
              msgboxText =  ['Invalid channel indexing.\n'...
                      'Channel index(ices) must be positive integer(s) but zero.'];
              title_msg = 'ERPLAB: pop_ploterps() invalid channel index';
              errorfound(sprintf(msgboxText, ERP.erpname), title_msg);
              return
      end     
      if max(binArray)>ERP.nbin
              msgboxText =  ['Bin(s) %g do(es) not exist within this erpset.\n'...
                      'Please, check your bin list'];
              title_msg = 'ERPLAB: pop_ploterps() invalid bin index';
              errorfound(sprintf(msgboxText, chanArray(chanArray>ERP.nchan)), title_msg);
              return
      end
      if min(binArray)<1
              msgboxText =  ['Invalid bin indexing.\n'...
                      'Bin index(ices) must be positive integer(s) but zero.'];
              title_msg = 'ERPLAB: pop_ploterps() invalid bin index';
              errorfound(sprintf(msgboxText, ERP.erpname), title_msg);
              return
      end      
      
      qMgfp   = p.Results.Mgfp;
      qBlc    = p.Results.Blc;
      qxscale = p.Results.xscale;
      qyscale = p.Results.yscale;
      qBox    = p.Results.Box;
      qLineWidth    = p.Results.LineWidth;
      qFontSizeChan = p.Results.FontSizeChan;
      qFontSizeLeg  = p.Results.FontSizeLeg;
      qaxsize  = p.Results.Axsize;
      
      if strcmpi(p.Results.Style,'Topo')
            qistopo = 1;
            qmeap   = 1;
      else
            qistopo = 0;
            if strcmpi(p.Results.Style,'Matlab')
                  qmeap = 1;
            else
                  qmeap = 0;
            end
      end
      if strcmpi(p.Results.YDir,'reverse')
            qisiy = 1;
      else
          qisiy = 0;
      end      
      if strcmpi(p.Results.Std,'on')
          qerrorstd = 1;
      else
          if ~isempty(str2num(p.Results.Std))
              qerrorstd = str2num(p.Results.Std);
          else
              qerrorstd = 0;
          end
      end
      if strcmpi(p.Results.HoldCh,'on')
          qholdch = 1;
      else
            qholdch = 0;
      end
      if strcmpi(p.Results.AutoYlim,'on')
            qyauto = 1;
      else
            qyauto = 0;
      end      
      if strcmpi(p.Results.BinNum,'on')
            qbinleg = 1;
      else
            qbinleg = 0;
      end           
      if strcmpi(p.Results.ChLabel,'on') %@@@@@@@@@@@@@@@@@@@@@@
            qchanleg = 1;
      else
            qchanleg = 0;
      end
      if strcmpi(p.Results.LegPos,'bottom')
            qlegepos = 1;
      elseif strcmpi(p.Results.LegPos,'right')
            qlegepos = 2;
      else
            qlegepos = 3;
      end
      if strcmpi(p.Results.Maximize,'on')
            ismaxim = 1;
      else
            ismaxim = 0;
      end
            
      minorticks = [0 0];
      
      if strcmpi(p.Results.MinorTicksX,'on')
            minorticks(1) = 1;
      else
            minorticks(1) = 0;
      end
      if strcmpi(p.Results.MinorTicksY,'on')
            minorticks(2) = 1;
      else
            minorticks(2) = 0;
      end
      
      posfig = p.Results.Position;
end

if qistopo
      if ~isfield(ERP.chanlocs,'theta')
            msgboxText =  ['%s  has not channel location info.\n'...
                           'Topographic plot will be terminated.'];
            title_msg = 'ERPLAB: pop_ploterps() missing info:';
            errorfound(sprintf(msgboxText, ERP.erpname), title_msg);
            return
      end
end

%
% Check & fix time range
%
% if qxscale(1)/1000<ERP.xmin
%       qxscale(1)=ERP.xmin*1000;
% end
% if qxscale(2)/1000>ERP.xmax
%       qxscale(2)=ERP.xmax*1000;
% end
try
      plotset = evalin('base', 'plotset');
      plotset.ptime.xscale = qxscale; % plotting memory for time window
      assignin('base','plotset', plotset);
catch
      ptime  = [];
      plotset.ptime  = ptime;
      assignin('base','plotset', plotset);
end

BinArraystr  = vect2colon(binArray, 'Sort','yes');
chanArraystr = vect2colon(chanArray);

ploterps(ERP, binArray, chanArray,  qistopo, qMgfp, qBlc, qxscale, qyscale,...
         qLineWidth, qisiy, qFontSizeChan, qFontSizeLeg, qmeap, qerrorstd,...
         qBox, qholdch, qyauto, qbinleg, qlegepos, ismaxim, posfig, qaxsize,...
         qchanleg, minorticks)

%
% History command
%
fn = fieldnames(p.Results);
erpcom = sprintf( 'pop_ploterps( %s, %s, %s ',  inputname(1), BinArraystr, chanArraystr);

for q=1:length(fn)
      fn2com = fn{q}; % inputname
      if ~ismember(fn2com,{'ERP','binArray','chanArray'})
            fn2res = p.Results.(fn2com); %  input value
            if ~isempty(fn2res)
                  if ischar(fn2res)
                        if ~strcmpi(fn2res,'off')
                              erpcom = sprintf( '%s, ''%s'', ''%s''', erpcom, fn2com, fn2res);
                        end
                  else
                        if ~ismember(fn2com,{'xscale','yscale'})
                              erpcom = sprintf( '%s, ''%s'', %s', erpcom, fn2com, vect2colon(fn2res,'Repeat','on'));
                        else                              
                              xyscalestr = sprintf('[ %.1f %.1f  %s ]', fn2res(1), fn2res(2), vect2colon(fn2res(3:end),'Delimiter','off'));
                              erpcom = sprintf( '%s, ''%s'', %s', erpcom, fn2com, xyscalestr);
                        end
                        
                  end
            end
      end
end
erpcom = sprintf( '%s );', erpcom);
try cprintf([0 0 1], 'COMPLETE\n\n');catch,fprintf('COMPLETE\n\n');end ;
return
