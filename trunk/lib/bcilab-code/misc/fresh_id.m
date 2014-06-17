function id = fresh_id(tag)
% Get an integer that is fresh/unique for a given tag.
% 
% In:
%   Tag : arbitrary string tag (must conform to MATLAB variable naming rules). The generated id's
%         are independent for different tags and local to the MATLAB session/instance.
%
% Out:
%   Id : An integer id that is fresh (i.e. unique), for a particular tag. When a new tag is first
%        used, this function will return 1. On every further call it will return the next higher 
%        unused integer. Closing the MATLAB session or calling "clear all" will reset any counter
%        back to 1 (also note that ids are not guaranteed to be unique across machines that run in 
%        parallel).
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2011-11-24

persistent ids;

try
    % get next higher id for the given tag
    id = ids.(tag).incrementAndGet();
catch
    try
        % tag doesn't exist yet: create
        ids.(tag) = java.util.concurrent.atomic.AtomicInteger();
        id = ids.(tag).incrementAndGet();
    catch
        if ~exist('tag','var')
            error('Please specify a tag for which you would like to obtain an id.'); end
        if ~isvarname(tag)
            error('Tags must be valid MATLAB variable names.'); end
    end
end
