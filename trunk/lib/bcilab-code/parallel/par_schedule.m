function [results,errors] = par_schedule(tasks,varargin)
% Schedule the given tasks across a pool of (possibly remote) workers.
% Results = par_schedule(Tasks, Options...)
%
% In:
%   Tasks : cell array of tasks; formatted as
%           * (evaluatable) string
%           * {function_handle, arg1,arg2,arg3, ...}
%           * struct('head',function_handle, 'parts',{{arg1,arg2,arg3, ...}})
%           (see also par_beginschedule for further details)
%
%   Options...: optional name-value pairs; possible names are:
%
%               see par_beginschedule and par_endschedule for the options
%
%               'keep': keep this scheduler alive for later re-use (default: false)
%                       if false, the scheduler will be destroyed after use, and re-created during the next run
%
% Out:
%   Results : cell array of results of the scheduled computations (evaluated tasks)
%   Errors  : cell array of exception structs for those results that could not be evaluated (in no particular order)
%
% See also:
%   par_worker, par_beginschedule, par_endschedule
%
% Notes:
%   Only the first output value of each task is taken and returned, though you can schedule 
%   hlp_wrapresults or hlp_getresult to get all or a specific output value of your task function.
%
% Example:
%   % run two computations (here as strings) in parallel on a pool of two nodes (assuming that MATLAB
%   % is running on those, executing the par_worker function)
%   results = par_schedule({'sin(randn(10))','exp(randn(10))'},'pool',{'localhost:32547','localhost:32548'})
% 
%   % as before, but pass the jobs as {function,arguments...}
%   results = par_schedule({@sin,randn(10)},{@exp,randn(10)}},'pool',{'localhost:32547','localhost:32548'})
%   
%   % as before, but do not destroy and re-create the scheduler between calls to par_schedule
%   results = par_schedule({@sin,randn(10)},{@exp,randn(10)}},'pool',{'localhost:32547','localhost:32548'},'keep'true)
%
%                       Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                       2010-08-29

opts = hlp_varargin2struct(varargin, 'keep',false);

id = par_beginschedule(tasks,opts);
[results,errors] = par_endschedule(id,opts);

if ~isempty(errors) && nargout <= 1
    rethrow(errors{1}{2}); end
