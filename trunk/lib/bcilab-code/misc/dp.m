function finisher = dp(message,varargin)
% stack-aware debug print
% Handle = dp(Message,Arguments...)
%
% This function allows to debug the progression of complex recursive functions. It prints a
% properly indented message immediately, and a complementing one when the function exits (or
% alternatively, when the returned handle is deleted). The two messages are of the form:
%
%   enter <functionname>: message
%   leave <functionname>: message
%
% In:
%   Message : optional message to display for the given function call (as in sprintf)
%
%   Arguments ; optional arguments to substitute inside Messsage (as in sprintf)
%
% Out:
%   Handle : Optional handle whose lifetime determines when the leave message is displayed
%
% Notes: 
%  If dp is used multiple times in the same function scope, the leave message will be displayed 
%  immediately before the next dp's enter message.
% 
% Dependencies: onCleanup()
%
% Examples:
%
%   function myfunction(...)
%   ...
%   dp('blah!');  % --> prints "enter myfunction: blah!" here
%   ...
%   < potentially recursive calls... >
%   ...
%                 % --> prints "leave myfunction: blah!" here
%
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2011-02-11

% process inputs
if ~exist('message','var')
    message = ''; end
if ~isempty(message)
    message = sprintf([': ' message],varargin{:}); end

% determine indentation
stack = dbstack;
stackdepth = length(stack);
indent = repmat(' ',1,stackdepth*2);

% issue leave message for any previous dp
if nargout == 0
    assignin('caller','dp_finalizer__',[]); end

% determine caller
caller = stack(2).name;

% display enter message
disp([indent 'enter ' caller message]);

% create leave message printer
finisher = onCleanup(@()disp([indent 'leave ' caller message]));

% and associate it with the calling function, if necessary
if nargout == 0
    assignin('caller','dp_finalizer__',finisher); end
