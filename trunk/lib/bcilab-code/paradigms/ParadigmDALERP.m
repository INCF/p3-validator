classdef ParadigmDALERP < ParadigmDataflowSimplified
    % Advanced paradigm for slow cortical potentials via the Dual-Augmented Lagrange method.
    %
    % The DAL-LF paradigm is, like para_windowmeans, a general method for operating on slow cortical
    % potentials. It is a special case of a more general framework described in [1] (using only its
    % "first-order" detector); the general variant, which can in addition capture oscillatory processes,
    % is further explained in para_dal. DAL is the name of the optimization method, and not an accepted
    % or recognized name for BCI paradigms using it (but is used here for the lack of a better name).
    %
    % The paradigm does not make a clear distinction between signal processing, feature extraction and
    % machine learning, unlike most others, but instead is a jointly optimized mapping from raw signal
    % (epoch) to probabilistic prediction, using an efficient regularized optimization method (further
    % detailed in [2]). The method usually out-performs the windowed means paradigm, and in addition
    % does not require any user parameters aside from the epoch limits and lowpass filtering band, and
    % is therefore one of the most useful BCI paradigms. The major drawback is the required computation
    % time (and in some cases, the required memory -- which can be ameliorated by reducing the sampling
    % rate of the data) due to the need for regularization. For this reason, it is a good strategy to
    % first run the paradigm without regularization to get a ball-park estimate of the attainable
    % accuracy, and only run the complete regularization when it makes sense.
    %
    % Just like the windowed means paradigm, DAL-LF is applicable to a wide range of event-related and
    % non-event-related scenarios, some of which are listed in para_windowmeans.
    %
    % Example: Consider the goal of predicting whether a person perceives a fixated on-screen item as
    % being unexpected (and/or erroneous, non-rewarding) or not. A calibration data set for this task
    % could be annotated with an event for every gaze fixation made by the user (obtained from an eye
    % tracker) while reading short on-screen text fragments which are either semantically correct or
    % incorrect. The two event types which identify the conditions sare 'corr' and 'err'. From the
    % literature [4,5], it can be assumed that these events should be accompanied by a characteristic
    % slow cortical potential in the EEG, which allows to infer the condition. The 'learner' parameter
    % will be specified as the default (relatively fine-grained) search over possible DAL regularization
    % parameter values.
    %
    %   calib = io_loadset('data sets/john/reading-errors.eeg')
    %   myapproach = {'DALERP', 'SignalProcessing',{'EpochExtraction',[0 0.8]}};
    %   [loss,model,stats] = bci_train('Data',calib, 'Approach',myapproach, 'TargetMarkers',{'corr','err'});
    %
    %
    % References:
    %  [1] Ryota Tomioka and Klaus-Robert Mueller, "A regularized discriminative framework for EEG analysis with application to brain-computer interface",
    %      Neuroimage, 49 (1) pp. 415-432, 2010.
    %  [2] Ryota Tomioka & Masashi Sugiyama, "Dual Augmented Lagrangian Method for Efficient Sparse Reconstruction",
    %      IEEE Signal Proccesing Letters, 16 (12) pp. 1067-1070, 2009.
    %  [3] Marcel van Gerven, Ali Bahramisharif, Tom Heskes and Ole Jensen, "Selecting features for BCI control based on a covert spatial attention paradigm."
    %      Neural Networks 22 (9), 1271-1277, 2009
    %  [4] Gehring, W.J., Coles, M.G.H., Meyer, D.E., Donchin, E.
    %      "The error-related negativity: an event-related brain potential accompanying errors."
    %      Psychophysiology 27, 34-41, 1990
    %  [5] Oliveira, F.T.P., McDonald, J.J., Goodman, D.
    %      "Performance monitoring in the anterior cingulate is not all error related: expectancy deviation and the representation of action-outcome associations"
    %      Journal of Cognitive Neuroscience. 19(12), 1994-2004, 2007
    %
    % Name:
    %   Low-Frequency DAL
    %
    %                           Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
    %                           2010-06-25
    
    methods
        
        function defaults = preprocessing_defaults(self)
            defaults = {'IIRFilter',{[0.1 0.5],'highpass'},'EpochExtraction',[-1.5 1.5],'Resampling',60,'SpectralSelection',[0.1 15]};
        end
        
        function defaults = machine_learning_defaults(self)
            defaults = 'dal';
        end
        
        function model = feature_adapt(self,varargin)
            args = arg_define(varargin, ...
                arg_norep('signal'), ...
                arg({'normalizers','NormalizationExponents'},[-0.25,-0.25],[],'Normalization exponents [lhs, rhs]. Two-element array of powers for the left-hand-side and right-hand-side normalization matrices that are applied to the data from the region.','cat','Feature Extraction'));
            
            X = num2cell(args.signal.data,[1 2]);
            model.P = {cov_shrink(cat(2,X{:})')^args.normalizers(1),cov_shrink(cat(1,X{:}))^args.normalizers(2)};
            model.chanlocs = args.signal.chanlocs;
            model.times = args.signal.times;
            global tracking;
            tracking.inspection.dal_model = model;
        end
        
        function features = feature_extract(self,signal,featuremodel)
            features = signal.data;
            for t=1:size(features,3)
                features(:,:,t) = featuremodel.P{1}*features(:,:,t)*featuremodel.P{2}; end
        end
        
        function visualize_model(self,parent,fmodel,pmodel,varargin) %#ok<*INUSD>
            % no parent: create new figure
            args = hlp_varargin2struct(varargin,'maxcomps',Inf,'regcurve',true,'paper',false);
            if isempty(parent)
                parent = figure('Name','Per-window weights'); end
            % get the spatial preprocessing matrix.
            P = fmodel.P{1};
            Q = fmodel.P{2};
            % obtain & reshape the model
            M = reshape(pmodel.model.w,size(P,2),[]);
            % do an SVD to get spatial and temporal filters
            [U,S,V] = svd(M);
            % display the model contents
            N = min(rank(M),args.maxcomps) + double(args.regcurve);
            px = ceil(sqrt(N));
            py = ceil(N/px);
            lim = -Inf;
            for x=1:N
                lim = max([lim;abs(inv(Q)*V(:,x)*S(x,x))]); end
            for x=1:N
                col = mod(x-1,px);
                row = floor((x-1) / px);
                idx = 1 + col + 2*row*px;
                if x < N || (x==N && ~args.regcurve)
                    subplot(2*py,px,idx,'Parent',parent);
                    topoplot(P*U(x,:)',fmodel.chanlocs);
                    t = title(sprintf('Component %.0f',x));
                    camzoom(1.2);
                    subplot(2*py,px,idx+px,'Parent',parent);
                    p1 = plot(fmodel.times,inv(Q)*V(:,x)*S(x,x),'black');
                    ylim([-lim lim]);
                    hold; p2 = plot(fmodel.times,zeros(length(Q),1),'black--');
                    l1 = xlabel('Time in s');
                    l2 = ylabel('Weight');
                elseif args.regcurve
                    subplot(2*py,px,idx+px,'Parent',parent);
                    t = title('Regularization curve');
                    p1 = plot(mean(pmodel.model.losses)); p2=[];
                    l1 = xlabel('Regularization parameter #');
                    l2 = ylabel('Prediction loss');
                end
                if args.paper
                    set([p1,p2],'LineWidth',3);
                    set([l1,l2,t],'FontUnits','normalized');
                    set([l1,l2,t],'FontSize',0.1);
                    set(gca,'FontUnits','normalized');
                    set(gca,'FontSize',0.1);
                end
            end
        end
        
        function layout = dialog_layout_defaults(self)
            layout = {'SignalProcessing.Resampling.SamplingRate', 'SignalProcessing.IIRFilter.Frequencies', ...
                'SignalProcessing.IIRFilter.Type', 'SignalProcessing.EpochExtraction', ...
                'SignalProcessing.SpectralSelection.FrequencySpecification', '', ...
                'Prediction.MachineLearning.Learner.Lambdas','Prediction.MachineLearning.Learner.LossFunction',...
                'Prediction.MachineLearning.Learner.Regularizer'};
        end
        
    end
end

