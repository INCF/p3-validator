function l = logsig(M)
% Compute the sigmoid function (e.g. used in logistic regression).
l= 1./(1+exp(-M));
