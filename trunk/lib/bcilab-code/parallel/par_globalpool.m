function res = par_globalpool(pool)
% Sets or gets the current global resource pool
global tracking
if exist('eng','var')
    tracking.parallel.pool = pool;
else
    try
        res = tracking.parallel.pool;
    catch
        res = {};
        tracking.parallel.pool = res;
    end
end
