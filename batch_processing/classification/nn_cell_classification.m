function [targets, net, tr, trainingSet] = nn_cell_classification(inputImages,inputSignals,inputTargets,varargin)
    % run a nnet model on an input series of filters and traces
    % biafra ahanonu
    % started: 2013.08.09
    % inputs
        %
    % options
        %
    % changelog
        %
    % TODO
        %

    % report the midpoint of the rise
    options.trainNet=1;
    %
    options.tauPct = 0.5;
    %
    options.net = feedforwardnet([42 7 3]);
    %
    options.net.trainFcn = 'trainscg';
    % get options
    options = getOptions(options,varargin);

    % trainingImages, testImages, trainNet, inputNet
    if(options.trainNet==1)
        % trainingSet=zeros(length(SpikeImageData(1).Image(:)),length(SpikeImageData),'double');
        % targets=ones(1,length(SpikeImageData));
        %length(SpikeImageData)
        for i=1:size(inputImages,1)
            thisSignal = inputSignals(i,:);
            [t_tau ~] = getTimeConstant(thisSignal,options.tauPct)
            trainingSet(:,i) = [t_tau];
        end
        size(targets)
        size(trainingSet)

        % train network
        %train(net,x1(1:5000,:),targets);
        % net = train(net,x1(1:5000,:),targets,'useParallel','yes','useGPU','yes','showResources','yes');
        % 'Modified' property now TRUE
    %     myCluster = parcluster('local');
    %     myCluster.NumWorkers = 6;
    %     saveProfile(myCluster);
        matlabpool open
        %net = train(net,trainingSet,targets,'useGPU','yes');
        [net tr] = train(net,trainingSet,targets,'useParallel','yes','showResources','yes');
        matlabpool close
    end

    % testSet=zeros(length(SpikeImageData(1).Image(:)),length(SpikeImageData),'double');
    % for i=1:length(SpikeImageData)
    %     testSet(:,i)=SpikeImageData(i).Image(:);
    % end
    % plotconfusion(targets, sim(net,testSet(1:83700,:)))
    % plotconfusion(targets, sim(net,trainingSet))
    % ploterrhist(targets - net(trainingSet))
    % output=sim(net,testSet)


function [t_tau inputSignal_tau] = getTimeConstant(inputSignal,tauPct)
    % biafra ahanonu
    % updated: 2013.12.07 [15:29:13]
    % gets the time constant
    tau_idx = find(inputSignal <= (max(inputSignal)*tauPct), 1, 'last')   % Index of y near time constant
    t = 0:length(inputSignal)-1;                  % Time vector
    t_tau = t([tau_idx  tau_idx+1])     % Check the time constant range
    inputSignal_tau = inputSignal([tau_idx  tau_idx+1])     % Check y at the time constant ranges