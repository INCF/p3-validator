function par_clearworkers(hostnames)
% Clear workers from the listed hostnames (or if those are unspecified, from the current pool).
% par_clearworkers(Hostnames)
%
% Note: this function erases all of the user's MATLAB processes on the given nodes; if there are
% unrelated MATLABs running, these will also be killed. This may also shoot down the master process
% itself if it is located on one of the unfortunate machines...
%
% In:
%   Hostnames : cell array of hostnames on which to acquire workers (duplicates and port assignments
%               will be ignored).
%
% Example:
%   % clear all workers on the given machines (of this user)
%   par_clearworkers({'computer1','computer2','computer3'})
%   
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2011-02-15

% optionally look up hostnames from the global pool
if ~exist('hostnames','var')
    global tracking; %#ok<TLEV>
    hostnames = tracking.parallel.pool;
end

% remove any port assignments
for i=1:length(hostnames)
    colons = hostnames{i}==':';
    if any(colons)
        hostnames{i} = hostnames{i}(1:find(colons)-1); end
end

% remove duplicates
hostnames = unique(hostnames);

% now clear them
fprintf('Clearing workers on %i machines...',length(hostnames));
for host = hostnames(:)'    
    [status,info] = system(sprintf('ssh -x %s killall MATLAB',host{1})); end %#ok<NASGU,ASGLU>
fprintf('done.\n');
