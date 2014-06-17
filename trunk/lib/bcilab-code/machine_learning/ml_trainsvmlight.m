function model = ml_trainsvmlight(varargin)
% Learn a linear or non-linear predictive model by Support Vector Machines, using SVMlight.
% Model = ml_trainsvmlight(Trials, Targets, Cost, Options...)
%
% SVMlight [1] is a comprehensive and fast implementation of Support Vector Machines [2] that
% supports, in addition to classification, also regression and ranking; it further offers a variety
% of kernels for state-of-the-art non-linear prediction. An alternative implementation which offers
% a greater variety of loss measures for classification is SVMperf (see ml_trainsvmperf). For
% further details, see ml_trainsvmperf.
%
% For non-linear ranking problems, this is the online applicable method in the toolbox, for
% non-linear regression problems, the only alternative is the Relevance Vector Machine, and for
% (arbitrary) non-linear classification problems, the alternatives is the Relevance Vector Machine
% and SVMperf.
%
% In:
%   Trials   : training data, as in ml_train
%
%   Targets  : target variable, as in ml_train
%
%   Cost     : regularization parameter, reasonable range: 2.^(-5:2:15), greater is stronger
%
%   Options  : optional name-value parameters to control the training details, see below in code for full help
%               'ptype': problem type: 'classification' (default), 'regression', and 'ranking'
%               'tube': epsilon width of tube for regression (default 0.1)
%               'balance': positive weight / negative weight
%              kernel parameters:
%               'kernel': ptype of kernel function (linear,poly,rbf,sigmoid,user); (default: 'rbf')
%               'gamma': parameter gamma in rbf kernel; reasonable search range: 2.^(-16:2:4) (default: 0.3)
%               'd': parameter d in polynomial kernel (default: 3)
%               's': parameter s in sigmoid/poly kernel (default: 1)
%               'r': parameter c in sigmoid/poly kernel (default: 1)
%               'u': parameter of user-defined kernel (default: '1')
%              misc options:
%               'eps': tolerance (e.g., 0.1)
%               'bias': bias present? (0,1)
%               'clean': clean inconsistent data before start? (0,1)
%               'verbose': verbosity level (0,1)
%               'scaling': pre-scaling, see hlp_findscaling (default: 'std')
%
% Out:
%   Model   : a linear model; 
%             classes indicates the class labels which the model predicts
%             sc_info is the scaling info
%
% Examples:
%   % learn a quick and dirty SVM model (without parameter search)
%   model = ml_trainsvmlight(trials,labels)
%
%   % as before, but this time learn a regression model
%   model = ml_trainsvm(trials,labels,1,'ptype','regression')
%
%   % learn an SVM model by searching over the cost parameter (note: quite slow)
%   model = utl_searchmodel({trials,labels},'args',{{'svmlight',search(2.^(-5:2:15))}})
%
%   % as before, but also search over the kernel scale parameter (note: really slow)
%   model = utl_searchmodel({trials,labels},'args',{{'svmlight',search(2.^(-5:2:15)),'gamma',search(2.^(-16:2:4))}})
%
%   % as before, but use a linear kernel (no need to search over gamma, then)
%   model = utl_searchmodel({trials,labels},'args',{{'svmlight',search(2.^(-5:2:15)),'kernel','linear'}})
%
%   % as before, but learn a ranking model
%   model = utl_searchmodel({trials,labels},'args',{{'svmlight',search(2.^(-5:2:15)),'kernel','linear','ptype','ranking'}})
%   
% See also:
%   ml_predictsvmlight, svmlearn
%
% References:
%   [1] Thorsten Joachims, "Learning to Classify Text Using Support Vector Machines"
%       Dissertation, Kluwer, 2002.
%   [2] Schoelkopf, B., and Smola, A. "Learning with Kernels: Support Vector Machines, Regularization, Optimization, and Beyond"
%       (Adaptive Computation and Machine Learning). The MIT Press, Dec. 2001.
%
%                           Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                           2010-04-04

arg_define([0 3],varargin, ...
    arg_norep('trials'), ...
    arg_norep('targets'), ...
    arg({'cost','Cost'}, search(2.^(-5:2:15)), [], 'Regularization parameter. Reasonable range: 2.^(-5:2:15), greater is stronger. By default, it is average(x*x) ^ -1.','cat','Core Parameters'), ...
    arg({'ptype','Type'}, 'classification', {'classification','regression','ranking'}, 'Type of problem to solve.','cat','Core Parameters'), ...
    arg({'kernel','Kernel'}, 'rbf', {'linear','rbf','poly','sigmoid','user'}, 'Kernel type. Linear, or Non-linear kernel types: Radial Basis Functions (general-purpose),  Polynomial (rarely preferred), Sigmoid (usually overly simple), User (user-defined kernel from kernel.h).','cat','Core Parameters'), ...
    arg({'g','RBFScale','gamma'}, search(2.^(-16:2:4)), [], 'Scaling parameter of the RBF kernel. Should match the size of structures in the data; A reasonable range is 2.^(-16:2:4).','cat','Core Parameters'), ...
    arg({'d','PolyDegree'}, uint32(3), [], 'Degree for the polynomial kernel.','cat','Core Parameters'), ...
    arg({'etube','EpsilonTube','tube'}, 0.1, [], 'Epsilon tube width for regression.','cat','Core Parameters'), ...
    arg({'rbalance','CostBalance','balance'}, 1, [], 'Relative cost of per-class errors. The factor by which training errors on positive examples outweight errors on negative examples.','cat','Core Parameters'), ...
    ...
    arg({'s','SigmoidPolyScale'}, 1, [], 'Scale of sigmoid/polynomial kernel.','cat','Miscellaneous'), ...
    arg({'r','SigmoidPolyBias'}, 1, [], 'Bias of sigmoid/polynomial kernel.','cat','Miscellaneous'), ...
    arg({'u','UserParameter'}, '1', [], 'User-defined kernel parameter.','cat','Miscellaneous','type','char','shape','row'), ...
    arg({'bias','Bias'}, false, [], 'Include a bias term. Only implemented for linear kernel.','cat','Miscellaneous'), ...
    arg({'scaling','Scaling'}, 'std', {'none','center','std','minmax','whiten'}, 'Pre-scaling of the data. For the regulariation to work best, the features should either be naturally scaled well, or be artificially scaled.','cat','Miscellaneous'), ...
    arg({'clean','CleanUp'}, false, [], 'Remove inconsistent training examples.','cat','Miscellaneous'), ...
    arg({'epsi','Epsilon','eps'}, 0.1, [], 'Tolerated solution accuracy.','cat','Miscellaneous'), ...
    arg({'verbose','Verbose'}, false, [], 'Show diagnostic output.','cat','Miscellaneous'));

if is_search(cost)
    cost = 1; end
if is_search(g)
    g = 0.3; end

% find the class labels
classes = unique(targets);
if length(classes) > 2
	% in this case we use the voter
    model = ml_trainvote(trials,targets,'1v1',@ml_trainsvmlight,@ml_predictsvmlight,varargin{:});
elseif length(classes) == 1
	error('BCILAB:only_one_class','Your training data set has no trials for one of your classes; you need at least two classes to train a classifier.\n\nThe most likely reasons are that one of your target markers does not occur in the data, or that all your trials of a particular class are concentrated in a single short segment of your data (10 or 20 percent). The latter would be a problem with the experiment design.');
else    
    % scale the data
    sc_info = hlp_findscaling(trials,scaling);
    trials = hlp_applyscaling(trials,sc_info);
    
    % remap target labels to -1,+1
    targets(targets==classes(1)) = -1;
    targets(targets==classes(2)) = +1;

    % rewrite sme string args to numbers
    ptype = hlp_rewrite(ptype,'classification','c','regression','r','ranking','p'); %#ok<*NODEF>
    kernel = hlp_rewrite(kernel,'linear',0,'poly',1,'rbf',2,'sigmoid',3,'user',4);
        
    % build the arguments
    args = sprintf('-z %s -c %f -v %d -w %f -j %f, -b %d -i %d -e %f -t %d -d %d -g %f -s %f -r %f -u %s', ...
        ptype,cost,verbose,etube,rbalance,bias,clean,epsi,kernel,d,g,s,r,u);

    % run the command
    model = svmlearn(trials,targets,args);
    model.sc_info = sc_info;
    model.classes = classes;
end
