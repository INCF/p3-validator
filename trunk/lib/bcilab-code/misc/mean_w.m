function X = mean_w(X,w)
% Compute the weighted mean of some data. 
% X = mean_w(X,w)
%
% The vector of weights must be nonnegative & its non-singleton dimension must match that of X.
%
% Dependencies: bsxfun()

X = sum(bsxfun(@times,X,w/sum(w)));