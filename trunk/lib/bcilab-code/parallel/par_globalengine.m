function res = par_globalengine(eng)
% Sets or gets the current global engine
global tracking
if exist('eng','var')
    tracking.parallel.engine = eng;
else
    try
        res = tracking.parallel.engine;
    catch
        res = 'local';
        tracking.parallel.engine = eng;
    end
end
