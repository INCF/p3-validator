function ef(varargin)
% Command-style shortcut for exp_fullform(varargin)
%
% See also: 
%   exp_fullform
%
% Example:
% >> ef var1 var2
%    var1 = 
%      ...
%    var2 = 
%      ...
%

if ~iscellstr(varargin)
    error('ef is to be used as a command, i.e. without brackets.'); end

for i=1:length(varargin)
    disp([varargin{i} ' = ']);
    disp(['  ' exp_fullform(evalin('caller',varargin{i}))]);
    disp('');
end