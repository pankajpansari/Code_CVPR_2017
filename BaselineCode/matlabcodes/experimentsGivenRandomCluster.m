function finalResult = experimentsGivenRandomCluster(resultFileName)

startup_all;
rng('shuffle');

%% Input parameters
params.lambda = [0 2 4 100];
params.numExp = 1; %num of random experiments

%Unary range
params.unaryStart = 0;
params.unaryEnd = 100;

%Grid size and clique size
params.sizeX = 50;
params.sizeY = 50;
params.wx = 4;
params.wy = 4;
params.numNodes = params.sizeX*params.sizeY;

%Use Pairwise or not
params.pairwise = 0;

%Labels and potential type
params.numLabels = 20;
params.useCard = 0; % use cardinality or not in case of hierPn

% Not being used
gammaMax = 10000;%*(numLabels - 1);
gamma = [zeros(1, params.numLabels), gammaMax];

%% Get the hop indices
hop = getHops(params.sizeX, params.sizeY, params.wx, params.wy, gamma, params.pairwise);
numHops = length(hop);
cliqueWeights = ones(numHops,1);

results = cell(params.numExp, length(params.lambda));
clustersMetrics = cell(params.numExp, 1);

for i = 1:params.numExp
    
    %% Generate random clusters and corresponding tree metric
    [clusters, metric] = getRandomClusters(params.numLabels);   
    
    clustersMetrics{i}.metric = metric;
    clustersMetrics{i}.clusters = clusters;    
    
    %% Generate random unaries and pairwise
    Dc = params.unaryStart + (params.unaryEnd - params.unaryStart).*rand(params.numLabels, params.numNodes);
    sG = sparse(params.numNodes,params.numNodes);
    
    for l = 1:length(params.lambda)
        
        %% get labeling using cooc
        tic;
        [L, E] = cooc_mex(sG, Dc, hop, metric, params.lambda(l), cliqueWeights);
        coocLabeling = double(L+1);
        timeTaken = toc;
        [uE pE hE mE] = compute_energy(sG, Dc, hop, coocLabeling, metric, params.lambda(l), cliqueWeights);
        
        fprintf('\n\nCOOC Exp:%d\tLambda:%d\tEnergy:%.3f\tTime:%.3f',i, params.lambda(l), mE, timeTaken);
        
        results{i,l}.inferenceType{1} = 'COOC';
        results{i,l}.labelings{1}.labeling = coocLabeling;
        results{i,l}.energy{1} = [uE pE hE mE];
        results{i,l}.timeTaken{1} = timeTaken;
        results{i,l}.lambda = params.lambda(l); 
        results{i,l}.timeHOP{1} = 0;  
        
        clear uE pE hE mE
        
        %% get labeling using Hier Pn-Potts
        tic;
        [hierLabeling timeHOP] = hierarchicalPnPottsLabeling(clusters, Dc, sG, hop, params.useCard, params.lambda(l), metric, cliqueWeights);
        timeTaken = toc;
        [uE pE hE mE] = compute_energy(sG, Dc, hop, hierLabeling, metric, params.lambda(l), cliqueWeights);
        
        fprintf('\nHier Exp:%d\tLambda:%d\tEnergy:%.3f\tTime:%.3f',i, params.lambda(l), mE, timeTaken);
        
        results{i,l}.inferenceType{2} = 'HierPn';
        results{i,l}.labelings{2}.labeling = hierLabeling;
        results{i,l}.energy{2} = [uE pE hE mE];
        results{i,l}.timeTaken{2} = timeTaken;  
        results{i,l}.timeHOP{2} = timeHOP;  
        
    end
    
    clear metric clusters
    
end

params.numTrees = 1; % don't change because the above code is generating only one tree (testing purpose)
finalResult.params = params;
finalResult.results = results;

if(nargin>=1)
    save(resultFileName,'finalResult');
end
%% plot results
%% plotGivenResults(finalResult); %need to update this code. there are few things hard coded








