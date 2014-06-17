function r = logdet(M)
% Compute log(det(A)) without the usual numerical inaccuracies.
r = 2 * sum(log(diag(chol(M))), 1);