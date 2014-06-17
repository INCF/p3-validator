function [measure,model,stats] = bci_train(varargin)
% Learn a predictive model given some data and approach, and estimate its performance.
% [Loss,Model,Statistics] = bci_train(Data, Approach, TargetMarkers, EvaluatationMetric, EvaluationScheme, ...)
%
% Learns a model of the connection between abstract 'cognitive state' annotations/definitions in a
% data set (e.g., event markers, target variables) and the actual biosignal data, so that the
% learned model can subsequently be used to predict the (defined) cognitive state of the person (in
% real time or offline). Also estimates the quality of the model's predictions, using a measure of
% 'mismatch' between what was defined for a given time point and what the model would predict (the
% 'loss').
%
%
% Model Computation
% =================
%
% The goal of BCI research is to enable a computer system to read the ongoing EEG (or other
% brain-/biosignals) of a person and predict from it, in real time, what his/her cognitive state is.
% Since the connection between biosignals and cognitive state includes some information that is
% highly specific to a person or group of persons, it can only be obtained from actual data of that
% person (or group), which is here called a 'calibration data set'. For modern expositions of the
% general problem and solutions, see [7] or [8].
%
% There is currently no general automated method to learn the connection (relation) between a
% calibration data set and the aspect of cognitive state that is to be predicted,  but there is a
% growing body of approaches, here called 'paradigms', each of which imposes a different set of
% assumptions about the nature of that relation. These paradigms tend to perform well if their
% assumptions match the data and if the required information is sufficiently accessible in the
% calibration data set. The result is a 'predictive model' in which the information about the
% connection of interest is captured (usually in some form of statistical mapping).
% 
% Almost all paradigms involve some parameters that can be varied to obtain a different variant of
% the paradigm (e.g., the frequency range of interest in the EEG signal), and the better these
% parameters are chosen, the better will be the attainable quality of the models that the paradigm
% can compute. In addition, there is the possibility to search over different values of parameters
% to find a good combination, if allowed by compute/time resources.
%
% bci_train requires that at least a paradigm is specified (predefined ones are in code/paradigms)
% and that a calibration data set, annotated with expected cognitive state is supplied. Since
% bci_train must learn a relation between raw signal and abstract (human-defined) cognitive state,
% the state must be specified by the user in a machine-accessible format. A typical 'encoding' of
% such state is created as follows. The user records a calibration data set from a person (a regular
% EEG recording). Througout this recording, the person is in different states at different times
% (preferably repeatedly and randomized), for example, instructed to think or feel a sequence of
% specific things (e.g., imagine a left/right hand gesture), or exposed to a series of artificial
% conditions (e.g., high/low excitement), such that the answer to a particular state question is
% known at particular times in the recording (e.g. was a left or right hand gesture being imagined
% at time X?). The times at which there is knowledge about the person's state, and its value at
% these times is encoded into the EEG as 'events', or 'markers'. In EEGLAB data sets, this is the
% field EEG.event, and its type (a string) would be used to encode the state value. Usually, events
% are produced by the software that guides the person though the calibration session and are
% recorded by the data acquisition system. 
%
% Which events in the data set are relevant and what is the desired output of the BCI for each of 
% these events of interest is specified via the parameter TargetMarkers (or may also be added as an 
% annotation for the data itself, using set_targetmarkers).
%
% Aside from the chosen paradigm's parameters, this is all there is to specify to bci_train in order
% to obtain a predictive model and its performance estimate. The paradigm's parameters are all
% optional, and are by default set as in the representative (or most commonly) published use of the
% paradigm, so most of them need to be specified only when the user wants to deviate from those
% values.
%
%
% Simple Example 
% ==============
%
% A model that predicts the laterality of imagined hand gestures can be computed as follows
% (assuming that the data set contains events with types 'left-imag' and 'right-imag', at the time
% points where the subject was instructed to imagine the respective action). Since the relevant
% brain signals (Event-Related Desynchronization, see [1]) are assumed to be oscillatory processes
% that originate in distinct areas of the brain, the CSP (Common Spatial Pattern, see, e.g., [2])
% paradigm is used here unmodified. The approach can be specified as a string (usually the acronym
% for one of the ParadigmXXX.m files in code/paradigms) or as a cell array containing that string 
% followed by optional name-value pairs to override/customize parameters.
%
%   calib = io_loadset('data_sets/john/gestures.eeg')
%   [loss,model,stats] = bci_train('Data',calib, 'Approach','CSP', 'TargetMarkers',{'left-imag','right-imag'})
%
% When the loss is good (low) enough to justify online use, the model would then be loaded by the
% user into BCILAB's online system and would predict, whenever it receives EEG that indicates an
% imagined left hand gesture, the number 1 with high probability (and 2 with low probability), and
% in the case of an imagined right hand gesture, the number 2 with high probability (and 1 with low
% probability). At times where the person being measured imagines neither of the defined gestures,
% the system may produce arbitrary predictions. To handle such cases, a further condition (the
% 'rest' condition) can be defined for the model, by inserting 'rest' events into the data set
% whenever the subject was in neither of the two other states. The model could then be trained as
%
%   [loss,model,stats] = bci_train('Data',calib, 'Approach','CSP', 'TargetMarkers',{'left-imag','right-imag','rest'}),
%
% and would predict 3 with high probability (and 1/2 with low probability) in periods where the
% person being measured is in a resting state (note: the function set_insert_markers can be used to
% insert markers of given types into specific periods of the data). Since CSP is by nature a method
% defined for only two conditions, the framework automatically applies it on every pair of
% conditions, which is called voting (see ml_trainvote). Another way to obtain similar results is by
% using two separate models at the same time, one to detect the type of imagination, and the other
% to detect whether an imagination (defined as a group of multiple event types) or resting is
% happening:
%
%   [lossA,modelA] = bci_train('Data',calib, 'Approach','CSP', 'TargetMarkers',{'left-imag','right-imag'}),
%   [lossB,modelB] = bci_train('Data',calib, 'Approach','CSP', 'TargetMarkers',{'rest', {'left-imag','right-imag'}})
%
% Though, in this case it is up to the application to combine the state probabilities that are
% produced by model B with those produced by model A.
%
% The majority of approaches override at least one parameter of the paradigm, as for example the
% EpochExtraction parameter of the signal processing chain, which determines the time range of 
% interest relative to the events. Thus, calibration of a BCI model usually proceeds in three steps 
% in BCILAB: 
%
%   calib = io_loadset('data_sets/john/gestures.eeg')
%   myapproach = {'CSP', 'SignalProcessing',{'EpochExtraction',[0.5 2.5]}};
%   [loss,model,stats] = bci_train('Data',calib, 'Approach',myapproach, 'TargetMarkers',{'left-imag','right-imag'})
%
%
% Loss Estimation
% ===============
%
% The most important question to ask about a predictive model is how well it performs, i.e. how well
% do its outputs match the desired outputs -- and for a complete system that performs actions
% depending on a predictive model, what overall cost is incurred by (potentially sub-optimal)
% behavior of the system. Both cases can be covered by a formal 'loss' metric [3]. Different types
% of systems / types of predictive models require different loss metrics, which can be chosen in the
% EvaluationMetric parameter from a set of pre-defined ones, or supplied as a custom function. An 
% introduction to various predefined loss functions and their uses is given in the help of the 
% function machine_learning/ml_calcloss.
%
% The loss of a model can be computed in a variety of settings. Most obviously and realistically, a
% model can be run online, and the loss incurred by its predictions can be recorded (for example,
% number of mis-classifications, virtual money lost by a BCI-supported gamer). This, however,
% requires multiple (controlled) runs through an experiment to compare different models and/or
% methods, which is usually prohibitively costly. A more effective approach is to record the online
% EEG/biosignal data and the desired outputs of the system whenever they are known, and then
% estimate the loss of any models "offline" on the data, using the loss metric that best reflects
% the actual loss in the chosen scenario (for example mis-classification rate or ROC area); this
% approach requires just one session, and can be used to compare arbitrarily many models post-hoc
% (using the function bci_predict). The caveat is that any chaotic dynamics that may unfold between
% a system mis-behaving and a user reacting are not covered by the estimate (for example, when a
% system fails for more than a minute, the user may start to control it more aggressively, which may
% in turn make it even more difficult for the model to interpret brain signals).
%
% Finally, a loss estimate can be computed directly by bci_train, on the given calibration data,
% using cross-validation (CV) [4]. This is a data resampling procedure in which models are
% repeatedly computed, each time on a different subset of the data (called the training set) and
% compared on another disjoint portion of the data (called the test set) using the defined (i.e.
% desired) outputs, and some user-selected loss measure. In the default CV, the data is partitioned
% into 10 blocks, where for each block, a model is computed on the remaining 9 ones and tested
% against the target values in the current block (called 10-fold blockwise CV). Other variants
% include k-fold randomized CV, where the data trials are randomly shuffled before a regular
% blockwise k-fold CV, n times repeated k-fold CV, in which n repeated runs over different
% shufflings are executed and results averaged, and leave-one-out CV (LOOCV), where a model is
% computed on all except for one trial, and is then tested on the held-out trial. The loss measure
% is by default chosen depending on the type of target values in the calibration set and the
% features of the paradigm so that the user rarely needs to override it (misclassification rate for
% categorical outputs, mean-square error for continuous outputs, negative log-likelihood for
% probabilistic regression models, etc.).
%
% The loss estimates of bci_train are very convenient and can be used to evaluate a large variety of
% models on data from a single calibration session. The caveat is that that the estimate
% systematically fails to cover certain features of actual online situations. First, chaotic
% dynamics are not captured, as in the other offline case, and second, only a certain fraction of
% the (time-varying) non-stationarities in the data are captured by the estimate. Most biosignals
% contain features that vary at certain time scales, from second to second (e.g., dopamine level),
% minute to minute (e.g., background situation), hour to hour (e.g., tiredness), day to day (e.g.,
% medication) and year to year (e.g., long-term brain plasticity), all of which can affect the
% output (quality) of the model. Since calibration sessions are usually short, training/test data is
% close to each other in time, and the situation typically has little variation (e.g. it may be all
% offline with no user control involved), the majority of non-stationarities that could degrade the
% model's performance are not captured, and the estimate is almost surely overly optimistic. How
% large this effect is depends among others on the stability of the features used by the model, the
% strength of assumptions imposed by the paradigm, and the variety/coverage of situations present in
% the calibration data.
%
%
% Paradigm Customization and Structure
% ====================================
%
% In the Approach declaration, a list of name-value pairs can be specified, for example 
% {'CSP', 'Resampling',200, 'SpectralSelection',[7 30], 'EpochExtraction',[-1.5 2.5]}, to override the 
% default values of the chosen paradigm for the given named parameters - practically all paradigms have
% named parameters (although some community-supplied ones may have position-dependent parameters -
% like most MATLAB functions). All parameters are basically passed through unmodified to the
% paradigm in question (usually one of the paradigms/ParadigmXXX classes), so the place to
% look up what can be specified is the help of the respective class, or by bringing up the GUI config 
% dialog for the given approach (see GUI tutorial).
%
% Most paradigms contain similar internal structure, and therefore share common components, which in
% turn means that most of them share multiple common parameters. It is therefore helpful to know
% these components. The internal structure of most paradigms contains a sequence of three overall
% data processing stages. The first stage, Signal Processing, receives (multi-channel) signals, such
% as EEG, and filters these signals to amplify and focus the information of interest, and to discard
% the remaining information. The outputs of the first stage are again signals, either continuous or
% epoched/segmented. The stage may have several successive sub-steps (most of them called filters,
% some called data set editing operations), such as resampling, frequency filtering, spatial
% filtering, time window selection, artifact removal, etc.. The toolbox offers a collection of
% pre-defined filter components (in filters/flt_*) and data set operations (in dataset_ops/set_*),
% each with their respective default parameters. Most paradigms use at least one or two of these
% components, usually with custom parameters for them, and the user can override these parameters by
% specifying the component name (e.g. 'resample' to control the settings of the used sampling rate
% filter, flt_resample) followed by the parameter value to be passed (e.g. 200 for 200 Hz in the
% case of flt_resample), or a cell array of parameters if the component accepts multiple parameters,
% such as flt_ica does. Furthermore, most paradigms not only use a subset of the provided filters,
% but instead use the entire default Signal Processing pipeline of the toolbox, explained in
% filters/flt_pipeline. For this reason, all parameters of flt_pipeline can be customized by the
% user for almost any paradigm (and not just those chosen by the paradigm), i.e. the user can enable 
% and configure stages in the default pipeline which are normally disabled in the given paradigm. Note
% that flt_pipeline offers a few alias names for some parameters, e.g. 'channels' can be used
% instead of 'selchans', both controlling filters/flt_selchans; these are listed in flt_pipeline.
%
% The second stage of most paradigms is the Feature Extraction stage, which receives the
% preprocessed signals from the Signal Processing, and extracts certain informative features (e.g.
% logarithm of the signal power). This stage is usually custom to the paradigm, and is therefore
% controlled by unique parameters (e.g. 'patterns' in the Common Spatial Patterns [2] paradigm,
% para_csp).
%
% Finally, the feature produced by the Feature Extraction are usually subjected to a last stage, the
% Machine Learning. In this, a learning component, which is one of the provided
% machine_learning/ml_train* functions, computes a statistical model of the feature distributions,
% and their relation to the desired output values. This component is generally selected via the
% 'learner' parameter, which is exposed by most paradigms. The learner can be specified as name tag, 
% such as 'lda', which refers to ml_trainlda. If the learner component contains parameters which shall 
% be costomized as well, a cell array is passed which contains the name tag followed by the custom 
% parameters, in the order of appearance in the respective learning function. For example, 
% 'learner',{'svmlinear',0.5} selects The linear SVM component and sets its Cost parameter to 0.5, 
% and 'learner',{'logreg',[],'variant','vb-ard'} selects the Logistic Regression component, keeps its 
% first parameter at the default value, and uses the custom variant 'vb-ard', which stands for 
% Variational Bayes with Automatic Relevance Determination (see, e.g., [7]). A small but useful subset 
% of the provided Signal Processing, Feature Extraction and Machine Learning components is compactly 
% described in [5].
%
%
% Customized Example
% ==================
%
% To obtain an online prediction of the working-memory load of a person, a calibration data set in
% which the person has to maintain varying numbers of items is his/her memory (e.g., using the
% n-back task, see [6]) can be used as a starting point. In this data set, conditions with one item
% in memory are marked with the event 'n1', conditions with two items in memory are marked with
% 'n2', etc. Assuming that working-memory load may be reflected in certain oscillatory processes,
% though in unknown locations and frequency bands, the paradigm Spec-CSP ([9]) is used as a basis.
% In its default configuration (see paradigms/ParadigmSpecCSP), it focuses on a relatively narrow
% frequency band, which shall be relaxed here (in particular, the theta band [10] should be
% included). Also, by default, the Spec-CSP paradigm selects data epochs at 0.5-3.5 seconds
% following each (selected) event, which shall be modified to [-2.5 2.5], to get a time coverage
% that is better adapted to the task. Finally, Spec-CSP by default contains a non-probabilistic
% classifier (Linear Discriminant Analysis, see machine_learning/ml_trainlda), which we want to
% change into a largely equivalent, but probabilistic one (Logistic regression, see
% machine_learning/ml_trainlogreg). Since we assume that the most important part of the spectrum
% will be the alpha and theta rhythm (peaked at ~10 and ~4Hz), but do not want to completely rule
% out other frequencies, we additionally impose a prior as a custom in-line (lambda) function of
% frequency). Since we have more than two classes, but the Spec-CSP is only defined for two classes,
% the framework automatically applies it to every pair of conditions and uses voting (see
% machine_learning/ml_trainvote) to arrive at per-class probabilities. Note that this is a major
% customization.
%
%   dataset = io_loadset('data sets/mary/nback.eeg')
%   myapproach = {'SpecCSP', ...
%       'SignalProcessing',{'EpochExtraction',[-2.5 2.5], 'FIRFilter',{'Frequencies',[2 4 33 34],'Type','minimum-phase'}}, ...
%       'Prediction',{'FeatureExtraction',{'SpectralPrior','@(f)1+exp(-(x-10).^2)+exp(-(x-4).^2'}, ...
%                     'MachineLearning',{'Learner','logreg'}}};
%   [loss,model,stats] = bci_train('Data',dataset, 'Approach',myapproach, 'TargetMarkers',{'n1','n2','n3'})
%
% This model will predict either 1,2, or 3 with high confidence, when the user is maintaining the
% respective number of items in his/her working memory, but will likely be fairly specific to the
% task on which it was calibrated.
%
%
% Parameter searching
% ===================
% 
% In some cases, the optimal setting of certain parameters of a paradigm might not be known, but may
% drastically affect the performance of the method. One example are the time boundaries w.r.t. to
% the supplied events, which may depend on the reaction time of the user, among other things.
% Another example are regularization parameters which are used to constrain the complexity of the
% learned model (see, e.g. [11]). Regularization is a very powerful concept which enables methods
% such as Support Vector Machines and LASSO, in which the parameter is neither designed to be
% manually selected nor is it very interpretable in terms of brain processes. But most importantly,
% manual selection of these parameters (by trial and error) invalidates the performance guarantees
% that are made by the loss estimates: the performance estimate found for the hand-selected model is
% likely far better than the actual performance of that model. This is because the influence of
% random fluctuations in the estimate over the possible parameters is maximized by the user when
% he/she accepts the best one as the actual performance of the method (similar in spirit to the
% fallacy of multiple hypothesis tests without correction).
%
% For these reasons, bci_train offers a generic mechanism to search over parameters (or parameter
% combinations), in user-defined intervals and granularity, and uses a nested cross-validation
% method to give unbiased loss estimates. In this method, the search for the best parameter (using
% cross-validation derived estimates) is done inside an outer cross-validation, in each of its
% steps, and is restricted to the respective training set of that step. This way, the performance of
% the search procedure itself can be objectively evaluated on held-out test data. The
% cross-validation scheme for this inner search procedure can be specified via the OptimizationScheme
% parameter (part of the Training-Options), which has the same format as the EvaluationScheme
% parameter. By default, it is set to a 5-fold blockwise cross-validation with 5 trials safety
% margin. As a downside, parameter search multiplies the time it takes to compute a model by a
% potentially large factor; the total computation time of bci_train is (# of folds in the outer
% cross-validation) * (# of folds in the inner cross-validation) * (# of parameter combinations) *
% (time to compute a single model). Thus, the evaluation (outer) cross-validation may in some cases
% be turned off ('eval_scheme' set to 0) to obtain a model in a reasonable time, e.g., between a
% calibration session and a subsequent online session.
%
% Any value supplied to the paradigm can be replaced by a search range, written as search(...), to
% indicate to bci_train that this parameter is subject to a search. The search() clause can be used
% in any place of the data passed to the paradigm (e.g. inside cell arrays and/or structs), and can
% run over any data type supported by MATLAB, such as numbers, strings, structs, and vectors.
%
%
% Parameter Search Examples
% =========================
%
% In the case of imagined hand gestures (see first example), the time period in which the user
% performs the imaginations may not be known in advance (e.g. one user may imagine to clench the
% fist, while another user may imagine a whole sequence of finger movements). Therefore, the exact
% boundaries of the relevant data are not known, and can be searched (or spectral heuristics could
% be used). We assume that the response time of the user following the instruction may vary between
% 0.25 seconds and 0.75 seconds, and we choose to search over the range at a granualarity of 0.1
% seconds. The time it takes until the imagination is finished may vary between 1.5 seconds and 4.5
% seconds, and we search over values at a granularity of 0.5 seconds. Thus, para_csp's default
% 'epoch' parameter [0.5,3.5] is replaced by [search(0.25:0.1:0.75), search(1.5:0.5:4.5)]:
%
%   calib = io_loadset('data sets/john/gestures.eeg')
%   myapproach = {'CSP' 'SignalProcessing',{'EpochExtraction',[search(0.25:0.1:0.75),search(1.5:0.5:4.5)]}};
%   [loss,model,stats] = bci_train('Data',calib, 'Approach',myapproach}, 'TargetMarkers',{'left-imag','right-imag'})
%
% Since the search runs over 6*7 parameters, and a 5x inner cross-validation is performed, the
% overall running time will be 6*7*5 = 210x the default running time. If such a procedure shall be
% run immediately prior to an online session, it is better to disable the outer cross-validation
% altogether, which brings the time down to 21x of the default.
%
%
% As a second example, suppose that the goal is to predict whether the user perceives some event as
% being erroneous or not. A possible calibration data set could contain events of two classes, 'err'
% and 'cor', which encode time points where the user encountered errorneous and correct events. The
% assumption is that the user's event processing is accompanied by a characteristic slow cortical
% potential [12] which allows to discern between the two conditions. As a paradigm, we use the
% ERP version of the Dual-Agumented Lagrange method [13], which makes few assumptions
% except that the cognitive process of interest is simple enough in its time/space behavior to be
% tractably recognized. We restrict the analysis to the period of -0.2 to 0.65s around the event,
% resample to 60Hz, filter to ~0.3-19Hz, and specify a custom parameter search range for the DAL machine
% learning function. The complexity of the learned model is controlled via a regularization
% parameter, called Lambda. This parameter is the first user-accessible parameter in the learning
% function ml_traindal (its first two parameters are implicitly specified by the framework and
% contain the actual data; this contract holds for all other learning functions
% machine_learning/ml_train*, as well). Instead of specifying an ad hoc value here, we instead
% let bci_train search over a large feasible interval.
%
%   calib = io_loadset('data sets/john/errorperception.eeg')
%   myapproach = {'DALERP', ...
%       'SignalProcessing',{'EpochExtraction',[-0.2 0.65]}, ...
%       'Prediction',{'MachineLearning',{'Learner',{'dal',search(2.^(8:-0.125:1))}}}};
%   [loss,model,stats] = bci_train('Data',calib,'Approach',myapproach, 'TargetMarkers',{'err','cor'})
%
% This example is for illustrative purposes because the ml_traindal has its own highly optimized 
% parameter search code, which would kick in if the first parameter was specified as an array of 
% possible values (i.e. without the search() clause).
%
% Statistics
% ==========
% 
% Aside from an average loss measure, a structure of additional statistics can be obtained from
% bci_train via its third output parameter, Statistics. The most relevant part of the statistics are
% the per-fold loss measures (computed in each cross-validation fold), which can be used to run
% statistical tests on the significance of outcomes, etc.; these are in the struct array .per_fold.
% This also includes the target values (.targ) and predicted values (.pred) for the trials in each
% fold, as well as the indices of the fold's trials in the full original data set (.indices).
% Depending on the type of loss measure, additional values may be available per fold (e.g. fraction
% of true and false positives, etc).
%
% If the model was obtained in a parameter search, the field .modelsearch contains the complete set of
% loss measures and computed models for each tested parameter combination (on the entire calibration
% set), which includes, among others, the regularization path for regularized classifiers, which
% allows for very detailed analyses of the computed models.
%
% Additional fields include, depending on the type of target variables, .classes and .class_ratio
% contain the possible output values of the model (e.g. [1,2,3,4,5] in a  standard 5-class
% classification task) as well as the fraction of data trials belonging to each class. The field
% .model contains the computed model, the field .expression contains an expression data structure
% which summarizes the parameters that went into the comptuation of the result(s), including those
% that determined the data set(s) used for calibration. The function hlp_tostring can format it into
% a human-readable string.
%
%
% Model Usage
% ===========
%
% The computed model can subsequently be used with other parts of the toolbox. Most importantly, the
% model can be used with the online system of the toolbox, either via one of the provided online
% plugins or directly through BCILAB's online application programming interface (API), explained in
% online_analysis/onl_*. Aside from online analysis, the model can be used for offline analysis of
% data sets, via the functions bci_predict (make predictions for every trial in a given data set),
% onl_stream (make predictions for desired time points in a given data set), and bci_preproc
% (preprocess a given data set into its pre-feature extraction form for analysis and visualization
% with EEGLAB tools). Finally, model properties can be visualized and inspected using visualization
% methods (visualizations/vis_*). The model can be saved to disk and re-loaded later.
%
%
% In:
%    --- core arguments ---
%
%    Data : Data set. EEGLAB data set, or stream bundle, or cell array of data sets / stream bundles
%           to use for calibration/evaluation.
%
%    Approach : Computational approach. Specification of a computational approach (usually a cell 
%               array, alternatively a struct). If a cell array, the first cell is the name of the 
%               paradigm (usually just the acronym of an existing ParadigmXXX class), and the rest are
%               name-value pairs specifying optional custom arguments for the paradigm.
%
%   TargetMarkers : Target markers. List of types of those markers around which data shall be used
%                   for BCI calibration; each marker type encodes a different target class (i.e.
%                   desired output value) to be learned by the resulting BCI model. 
%                   
%                   This can be specified either as a cell array of marker-value pairs, in which
%                   case each marker type of BCI interest is associated with a particular BCI output 
%                   value (e.g., -1/+1), or as a cell array of marker types (in which case each 
%                   marker will be associated with its respective index as corresponding BCI output 
%                   value, while nested cell arrays are also allowed to group markers that correspond
%                   to the same output value). See help of set_targetmarkers for further explanation.
%
%
%   --- miscellaneous arguments ---
%
%   EvaluationMetric : Evaluation metric. The metric to use in the assessment of model performance
%                      (via cross-validation). Can be empty, a string, or a function handle.
%                      See ml_calcloss() for the options (default: [] = auto-select between 
%                      kullback-leibler divergence ('kld'), mean square error ('mse'), mis-classification 
%                      rate ('mcr') and negative log-likelihood ('nll') depending on the type of the 
%                      target and prediction variables, further detailed in ml_calcloss())
%
%   EvaluationScheme : Evaluation scheme. Cross-validation scheme to use for evaluation. See 
%                      utl_crossval for the default settings when operating on a single recording
%                      (there it is called 'scheme'), and utl_collection_partition when operating on
%                      a collection of data sets. In the case of single data sets, a reasonable
%                      choice for final results is {'chron',10,5} which stands for 10-fold
%                      chronological/blockwise cross-validation with 5 trials margin between
%                      training and test sets. Default: {'chron',5,5}, which is twice as fast, for
%                      more rapid workflow. A standard choice in machine learning is 10-fold randomized
%                      cross-validation, which you get by setting this parameter to 10 (though it is
%                      not ideal for time-series data).
%
%   OptimizationScheme : Optimization scheme. Cross-validation scheme to use for parameter search 
%                        (this is a nested cross-validation, only performed if there are parameters
%                        to search). The format is the same as in EvaluationScheme; default is
%                        {'chron',5,5}, which is a reasonable choice for final results.
%   
%   GoalIdentifier : Goal identifier. This is only used for training on multiple recordings and
%                    serves to identify the data set on which the BCI shall eventually be used
%                    (e.g., the Subject Id, Day, etc. of the goal data set).
%
%   EpochBounds : Epoch bounds override. Tight upper bound of epoch windows used for epoching (by
%                 default [-5 5]). This is only used if the cross-validation needs to run on
%                 continuous data because a continuous-data statistic needs to be computed over the
%                 training set (such as ICA).
%
%   CrossvalidationResources : Cross-validation parallelization. Same meaning and options as the
%                              ParameterSearchEngine parameter, however for the cross-validations.
%                              By default set to 'global'.
%
%   ParameterSearchResources : Parameter search parallelization. If set to 'global', the global BCILAB
%                              setting will be used to determine when to run this computation. If set
%                              to 'local', the computation will be done on the local machine.
%                              Otherwise,the respective scheduler will be used to distribute the
%                              computation across a cluster (default: 'local')
%   
%   NestedCrossvalResources : Nested cross-validation parallelization. If set to 'global', the
%                             global BCILAB setting will be used to determine when to run this
%                             computation. If set to 'local', the computation will be done on the
%                             local machine. Otherwise,the respective scheduler will be used to
%                             distribute the computation across a cluster (default: 'local')
%
%   ResourcePool : Parallel compute resouces. If set to ''global'', the globally set BCILAB resource 
%                  pool will be used, otherwise this should be a cell array of 'hostname:port'
%                  strings (default: 'global')
%
% Out:
%   Loss       : a measure of the overall performance of the paradigm combination, w.r.t. to the 
%                target variable returned by gettarget, computed by the specified loss metric.
%
%   Model      : a predictive model ("detector"), as computed by the specified paradigm; can be 
%                loaded into the online system via onl_loaddetector, applied offline to new data via
%                bci_predict, and analyzed using various visualizers
%
%   Statistics : additional statistics, as produced by the specified metric; if the model itself is 
%                determined via parameter search, further statistics from the model searching are in
%                the subfield stats.model
%
% Examples:
%   % assuming that a data set has been loaded, and a computational approach has been defined 
%   % similarly to the following code:
%   traindata = io_loadset('bcilab:/userdata/tutorial/imag_movements1/calib/DanielS001R01.dat');
%   myapproach = {'CSP' 'SignalProcessing',{'EpochExtraction',[0 3.5]}};
%
%   % learn a model and get the mis-classification rate, as well as statistics
%   [trainloss,lastmodel,laststats] = bci_train('Data',traindata,'Approach',myapproach,'TargetMarkers',{'StimulusCode_2','StimulusCode_3'});
%
%   % as before, but use a coarser block-wise (chronological) cross-validation (5-fold, with 3 trials margin)
%   [trainloss,lastmodel,laststats] = bci_train('Data',traindata,'Approach',myapproach,'EvaluationScheme',{'chron',5,3}'TargetMarkers',{'StimulusCode_2','StimulusCode_3'});
%
%   % as before, but use a 10-fold randomized cross-validation (rarely recommended)
%   [trainloss,lastmodel,laststats] = bci_train('Data',traindata,'Approach',myapproach,'EvaluationScheme',10,'TargetMarkers',{'StimulusCode_2','StimulusCode_3'});
%
%   % as before, using a 10-fold, 10x repeated randomized cross-validation
%   [trainloss,lastmodel,laststats] = bci_train('Data',traindata,'Approach',myapproach,'EvaluationScheme',[10 10],'TargetMarkers',{'StimulusCode_2','StimulusCode_3'});
%
%   % using a different loss measure (here: mean-square error, instead of the default mis-classification rate)
%   [trainloss,lastmodel,laststats] = bci_train('Data',traindata,'Approach',myapproach,'EvaluationMetric','mse','TargetMarkers',{'StimulusCode_2','StimulusCode_3'});
%
%
% References:
%   [1] Pfurtscheller, G., and da Silva, L. "Event-related EEG/MEG synchronization and desynchronization: basic principles."
%       Clin Neurophysiol 110, 1842-1857, 1999
%   [2] Ramoser, H., Mueller-Gerking, J., Pfurtscheller G. "Optimal spatial filtering of single trial EEG during imagined hand movement." 
%       IEEE Trans Rehabil Eng. Dec 8 (4): 441-6, 2000
%   [3] MacKay, D. J. C. "Information theory, inference, and learning algorithms." 
%       Cambridge University Press, 2003.
%   [4] Duda, R., Hart, P., and Stork, D., "Pattern Classification.", Second Ed.
%       John Wiley & Sons, 2001.
%   [5] Dornhege, G. "Increasing Information Transfer Rates for Brain-Computer Interfacing."
%       Ph.D Thesis, University of Potsdam, 2006.
%   [6] Owen, A. M., McMillan, K. M., Laird, A. R. & Bullmore, E. "N-back working memory paradigm: A meta-analysis of normative functional neuroimaging studies."
%       Human Brain Mapping, 25, 46-59, 2005
%   [7] Bishop, C. M. "Pattern Recognition and Machine Learning." 
%       Information Science and Statistics. Springer, 2006.
%   [8] Hastie, T., Tibshirani, R., and Friedman, J. H. "The elements of statistical learning (2nd Ed.)." 
%	    Springer, 2009.
%   [9] Tomioka, R., Dornhege, G., Aihara, K., and Mueller, K.-R.. "An iterative algorithm for spatio-temporal filter optimization." 
%       In Proceedings of the 3rd International Brain-Computer Interface Workshop and Training Course 2006, pages 22-23. Verlag der Technischen Universitaet Graz, 2006.
%   [10] Buzsaki, G., "Rhythms of the brain"
%        Oxford University Press US, 2006
%   [11] Tibshirani, R. . "Regression Shrinkage and Selection via the Lasso"
%        Journal of the Royal Statistical Society, Series B (Methodology) 58 (1): 267-288, 1996
%   [12] Holroyd, C.B., Coles, M.G.. "The neural basis of human error processing: reinforcement learning, dopamine, and the error-related negativity"
%        Psychological Review, 109, 679-709, 2002
%   [13] Tomioka, R. and Mueller, K.-R. "A regularized discriminative framework for EEG analysis with application to brain-computer interface"
%        Neuroimage, 49 (1) pp. 415-432, 2010.
%   [14] Onton J & Makeig S. "Broadband high-frequency EEG dynamics during emotion imagination."
%        Frontiers in Human Neuroscience, 2009. 
%
% See also:
%   bci_predict, bci_batchtrain, bci_visualize, bci_annotate, io_loadset,
%   onl_simulate, onl_newpredictor, utl_crossval, utl_searchmodel,
%   utl_nested_crossval
%
%                               Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                               2010-04-24

% handle the legacy cell array syntax by reformatting it to the new one
if length(varargin) == 1 && iscell(varargin{1})    
    varargin = varargin{1}; end

% get the options
opts = arg_define(varargin, ...
    ... % core parameters ...
    arg_norep({'data','Data'},mandatory,[],'Data set. EEGLAB data set, or stream bundle, or cell array of data sets / stream bundles to use for calibration/evaluation.'), ...
    arg({'approach','Approach'},[],[],'Computational approach. Specification of a computational approach (usually a cell array, alternatively a struct).'), ...
    arg({'markers','TargetMarkers'},{},[],'Target markers. List of types of those markers around which data shall be used for BCI calibration; each marker type encodes a different target class (i.e. desired output value) to be learned by the resulting BCI model. This can be specified either as a cell array of marker-value pairs, in which case each marker type of BCI interest is associated with a particular BCI output value (e.g., -1/+1), or as a cell array of marker types (in which case each marker will be associated with its respective index as corresponding BCI output value, while nested cell arrays are also allowed to group markers that correspond to the same output value). See help of set_targetmarkers for further explanation.'), ...
    arg({'metric','EvaluationMetric','Metric','cvmetric'},'auto',{'auto','mcr','mse','nll','kld','mae','max','rms','bias','medse','auc','cond_entropy','cross_entropy','f_measure'},'Evaluation metric. The metric to use in the assessment of model performance (via cross-validation); see also ml_calcloss.'), ...
    arg({'eval_scheme','EvaluationScheme'},[],[],'Evaluation scheme. Cross-validation scheme to use for evaluation. See utl_crossval for the default settings when operating on a single recording, and utl_collection_partition when operating on a collection of data sets.'), ...
	arg({'opt_scheme','OptimizationScheme'},{'chron',5,5},[],'Optimization scheme. Cross-validation scheme to use for parameter search (this is a nested cross-validation, only performed if there are parameters to search).'), ...
    ... % misc parameters ...
    arg({'goal_identifier','GoalIdentifier'},{},[],'Goal identifier. This is only used for training on multiple recordings and serves to identify the data set on which the BCI shall eventually be used (e.g., Subject Id, Day, etc.).'), ...
    arg({'epoch_bounds','EpochBounds'},[],[],'Epoch bounds override. Tight upper bound of epoch windows used for epoching (by default the parameter to set_makepos / EpochExtraction). This is only used if the cross-validation needs to run on continuous data because a continuous-data statistic needs to be computed over the training set (such as ICA).'), ...
    ... % parallel computing parameters
    arg({'engine_cv','CrossvalidationResources'},'global',{'global','local','BLS','ParallelComputingToolbox','Reference'},'Cross-validation parallelization. If set to ''global'', the global BCILAB setting will be used to determine when to run this computation. If set to ''local'', the computation will be done on the local machine. Otherwise,the respective scheduler will be used to distribute the computation across a cluster.'), ...
    arg({'engine_gs','GridSearchResources'},'local',{'global','local','BLS','ParallelComputingToolbox','Reference'},'Grid search parallelization. If set to ''global'', the global BCILAB setting will be used to determine when to run this computation. If set to ''local'', the computation will be done on the local machine. Otherwise,the respective scheduler will be used to distribute the computation across a cluster.'), ...
    arg({'engine_ncv','NestedCrossvalResources'},'local',{'global','local','BLS','ParallelComputingToolbox','Reference'},'Nested Cross-validation parallelization. If set to ''global'', the global BCILAB setting will be used to determine when to run this computation. If set to ''local'', the computation will be done on the local machine. Otherwise,the respective scheduler will be used to distribute the computation across a cluster.'), ...
    arg({'pool','ResourcePool'},'global',[],'Parallel compute resouces. If set to ''global'', the globally set BCILAB resource pool will be used, otherwise this should be a cell array of hostname:port strings.'), ...
    ... % some more misc parameters
    arg({'prune_datasets','PruneDatasets'},true,[],'Prune datasets from results. If true, any occurrence of a data set in the resulting model or stats struct will be replaced by its symbolic expression or a placeholder string.'));

% if any of the following warnings is ever triggered, the state of data in the caches might have gotten
% seriously messed up. If disk caching is turned on, it is best to purge the recent cache entries
% back to when this warning first occurred. note: the toolbox never globally disables these variables;
% check if a script has turned them off
if ~hlp_resolve('fingerprint_create',true)
    disp('WARNING: Data fingerprint creation is currently disabled (fingerprint_create set to 0). If you have been modifying your data sets manually in scripts before calling bci_train, it is recommended that you re-start your session, as some of your edits might have gone unnoticed.'); end
if ~hlp_resolve('fingerprint_check',true)
    disp('WARNING: Data fingerprint checking is currently disabled (fingerprint_check set to 0). You can re-enable it by calling exp_set_scoped(@fingerprint_check,1) in the command line.'); end

% --- pre-process the inputs ---

% parse the approach (either it's a paradigm name string, a cell array, or a struct)
if ischar(opts.approach)
    opts.approach = struct('paradigm',opts.approach, 'parameters',{{}});
elseif iscell(opts.approach)
    opts.approach = struct('paradigm',opts.approach{1}, 'parameters',{opts.approach(2:end)}); 
elseif ~all(isfield(opts.approach,{'paradigm','parameters'}))
    error('The approach must be given either as struct with fields ''paradigm'' and ''parameters'' or as a cell array of the form {paradigmname, param1, param2, param3, ...}'); 
end


% parse the paradigm identifier of the approach
paradigm_name = opts.approach.paradigm;
if ischar(paradigm_name)
    if exist(['Paradigm' paradigm_name],'class')
        paradigm_name = ['Paradigm' paradigm_name]; end
    if ~exist(paradigm_name,'class')
        error('A paradigm class with the name (%s) was not found.',paradigm_name); end
elseif isa(paradigm_name,'function_handle')
    info = functions(paradigm_name);
    paradigm_name = class(info.workspace{1}.instance);
    if ~strncmp(paradigm_name,'Paradigm',8)
        error('The Paradigm argument must be the name of a Paradigm class.'); end
else
    error('The Paradigm argument must be the name of a class (optionally omitting the "Paradigm" prefix).');
end
instance = eval(paradigm_name); %#ok<NASGU>
calibrate_func = eval('@instance.calibrate');
predict_func = eval('@instance.predict');


% parse the parameters of the approach: take the cartesian product over all
% grid search() expressions in the parameters
paradigm_parameters = hlp_flattensearch(opts.approach.parameters);
% update the list of filters and machine learners if necessary (to get up-to-date lists of supported modules)
flt_pipeline('update');
ml_train('update');
if ~is_search(paradigm_parameters)
    % use the paradigm function to fill in all defaults (etc) for unspecified arguments
    paradigm_parameters = arg_report('vals',calibrate_func,paradigm_parameters);
else
    % fill in the defaults for each individual search item
    for k=1:length(paradigm_parameters.parts)
        paradigm_parameters.parts{k} = arg_report('vals',calibrate_func,paradigm_parameters.parts{k}); end
end

% if the EpochBounds are undefined, see if we can infer them from the data
if isempty(opts.epoch_bounds)
    bounds = collect_instances(paradigm_parameters,'epobounds'); % note: direct name reference to set_makepos's parameter
    if ~isempty(bounds)
        bounds = vertcat(bounds{:});
        % we use an upper bound of the encountered bounds if multiple (can be multiple if in a 
        % parameter search, or if different bounds are assigned to multiple streams) plus some slack
        opts.epoch_bounds = [min(bounds(:,1))-0.1 max(bounds(:,2))+0.1];
    end
end

paradigm_parameters = {paradigm_parameters};



% --- set up common arguments to the cross-validation & model search ---

% turn data into a trivial collection, if necessary
if isstruct(opts.data)
    opts.data = {opts.data}; end

% do some pre-processing and uniformization of the data
for k=1:length(opts.data)
    % turn each data set into a stream bundle, if necessary
    if ~isfield(opts.data{k},'streams')
        opts.data{k} = struct('streams',{opts.data(k)}); end
    % annotate target markers in 1st stream according to the specified event types
    if ~isempty(opts.markers)
        if isempty(opts.epoch_bounds)
            disp('Note: TargetMarkers were specified, but epoch bounds could not be deduced from the data (likely processing is not using epoch extraction). Assuming some default bounds [-0.5 0.5].'); 
            opts.epoch_bounds = [-0.5 0.5];
        end
        % (there are 2 possible TargetMarker formats to handle)
        if all(cellfun('isclass',opts.markers,'char') | cellfun('isclass',opts.markers,'cell'))
            opts.data{k}.streams{1} = set_targetmarkers('Signal',opts.data{k}.streams{1},'EventTypes',opts.markers,'EpochBounds',opts.epoch_bounds);
        else
            opts.data{k}.streams{1} = set_targetmarkers('Signal',opts.data{k}.streams{1},'EventMap',opts.markers,'EpochBounds',opts.epoch_bounds);
        end
    end    
    % check the bundle for consistency: in particular, whether the data matches the .tracking field
    opts.data{k} = utl_check_bundle(opts.data{k});
end
% ... and store some tracking information for the resulting model
source_data = opts.data;
for k=1:length(source_data)
    source_data{k}.streams = cellfun(@utl_purify_expression,source_data{k}.streams,'UniformOutput',false); end

% determine whether we have to send our data over the network
nonlocal = false;
for computescope = {'engine_cv','engine_gs','engine_ncv'}
    if strcmp(opts.(computescope{1}),'global')
        nonlocal = nonlocal || ~strcmp(par_globalengine,'local'); 
    else 
        nonlocal = nonlocal || ~strcmp(opts.(computescope{1}),'local');
    end
end

if nonlocal
    % if we're running non-locally, transfer only a minimal amount of data (i.e. just the expressions) over the network
    opts.data = source_data;
    % ... and make sure that these expressions get properly cached on the server side...
    for k=1:length(opts.data)
        opts.data{k}.streams = cellfun(@(x)exp_block({exp_rule(@memoize,{'memory',1})},x),opts.data{k}.streams,'UniformOutput',false); end
end


if isscalar(opts.data)    
    % got a single recording: cross-validate within it
    opts.data = opts.data{1};
    if isempty(opts.eval_scheme)
        opts.eval_scheme = {'chron',5,5}; end
    % set up the utl_crossval (et al.) arguments for a within-set cross-validation
    crossval_args = { ...
        'trainer', @(trainset,varargin) utl_complete_model(calibrate_func('collection',{trainset},varargin{:}),predict_func), ...
        'tester', @(testset,model) predict_func(utl_preprocess_bundle(testset,model),model), ...
        'partitioner', @(dataset,inds) utl_partition_bundle(dataset,inds,opts.epoch_bounds), ...
        'target', @(dataset) set_gettarget(dataset.streams{1}), ...
        'argform','clauses', ...
        'args',paradigm_parameters};
else
    % got a data set collection: cross-validate across them
    if isempty(opts.eval_scheme)
        opts.eval_scheme = {}; end
    % set up the utl_crossval (et al.) arguments for a cross-validation on data sets
    crossval_args = { ...
        'trainer', @(traincollection,varargin) utl_complete_model(calibrate_func('collection',traincollection,varargin{:}),predict_func), ...
        'tester', @(testcollection,model) utl_collection_tester(testcollection,model,predict_func), ...
        'partitioner', @(fullcollection,inds) utl_collection_partition(fullcollection,inds,opts.eval_scheme), ...
        'target', @utl_collection_targets, ...
        'argform','clauses', ...
        'args',[paradigm_parameters {'goal_identifier',opts.goal_identifier}]};
end

% pre-pend some user arguments of bci_train (e.g., pool, policy, ...) to the control arguments (to be overridden by what is defined in crossval_args)
crossval_args = [{rmfield(opts,{'data','approach','markers','goal_identifier','epoch_bounds'})} crossval_args];

% note: the following line is a fancy way of calling [measure,model,stats] = run_computation(opts,crossval_args); 
% what is different is that the variables fingerprint_check and fingerprint_create will be set to 0
% for the scope of that computation (effectively disabling some unnecessary checks for performance)
[measure,model,stats] = hlp_scope({'fingerprint_check',0,'fingerprint_create',0},@run_computation,opts,crossval_args);

% annotate the result with additional info
stats.is_result = true;
stats.timestamp = now;
model.paradigm = paradigm_name;
model.options = paradigm_parameters;
model.source_data = source_data;
model.control_options = rmfield(opts,'data');
model.epoch_bounds = opts.epoch_bounds;
% remove some additional data overhead from model & stats to keep them small
if opts.prune_datasets
    model = utl_prune_datasets(model);
    stats = utl_prune_datasets(stats);
end
model = utl_prune_handles(model);
stats = utl_prune_handles(stats);
model.tracking.prediction_function = paradigm_name;
stats.model = model;



% run the actual computation of bci_train (model search/training, (nested) cross-validation)
function [measure,model,stats] = run_computation(opts,crossval_args)
t0 = tic;
% issue model search
job = par_beginschedule({{@hlp_getresult,{1:2}, @utl_searchmodel, opts.data, crossval_args{:}, 'scheme',opts.opt_scheme}}, opts, 'engine',opts.engine_cv, 'keep',false);
% estimate the model performance, if requested (0-fold cross-validation = cross-validation turned off)
if ~isequal(opts.eval_scheme,0)
    [measure,stats] = utl_nested_crossval(opts.data, crossval_args{:});
else
    measure = NaN;
end
% collect & aggregate results
results = par_endschedule(job, 'keep',false);
[model,stats.modelsearch] = deal(results{1}{:});
model.tracking.computation_time = toc(t0);


% collect all instances of values of the given field in a data structure
function res = collect_instances(x,field)
res = {};
if isstruct(x)
    for fn=fieldnames(x)'
        fname = fn{1};
        if strcmp(fname,field)
            % this is our field: aggregate all instances as a cell array
            tmp = {x.(fname)};
        else
            tmp = collect_instances({x.(fname)},field);
        end
        if ~isempty(tmp)
            res = [res tmp(:)]; end
    end
elseif iscell(x)
    for c=1:numel(x)
        res = [res collect_instances(x{c},field)]; end
end
