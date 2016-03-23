function finalResult = wrapperParsimoniousCOOC(configurationFile)

startup_all;

%% Extract the potentials and other information from the given configuration file
[numNodes, numLabels, Dc, sG, hop, cliqueWeights, truncationFactor, lambda] = getInfoConfFile(configurationFile);

fprintf('Number of variables = %d \n', numNodes);
fprintf('Number of labels = %d \n', numLabels);
fprintf('Truncation factor = %d \n', truncationFactor);
fprintf('Lambda = %d \n', lambda);
%fprintf('sG = %d \n', sG);
%fprintf('hop = %d \n', hop);

%% Input parameters
params.numNodes = numNodes;
params.numLabels = numLabels;
params.truncationFactor = truncationFactor;
params.lambda = lambda;

% Default parameters
params.numTrees = 1;
params.pairwise = 0;
params.useCard = 0; % use cardinality or not in case of hierPn

%%potentialType=1/2 -> truncated Linear/Quad
%%potentialType=3/4 -> random Metric/Semi-metric
params.potentialType = 1;

results = cell(1, 1);
clustersMetrics = cell(1, 1);

%% Generate random metrics and get the clusters
metric = getRandomMetrics(params.numLabels, params.potentialType, params.truncationFactor);

%% get the k random trees
clusters = cell(1,1);
for k = 1:params.numTrees
    clusters{k} = anyMetric2treeMetricRandomFakcharoenphol(metric);
end

clustersMetrics{1}.metric = metric;
clustersMetrics{1}.clusters = clusters;


%%% get labeling using cooc
%tic;
%[L, E] = cooc_mex(sG, Dc, hop, metric, params.lambda, cliqueWeights);
%coocLabeling = double(L+1);
%fileID = fopen('labeling.txt', 'w');
%fprintf(fileID, '%d\n', coocLabeling);
%fclose(fileID);
%timeTaken = toc;
%[uE, pE, hE, mE] = compute_energy(sG, Dc, hop, coocLabeling, metric, params.lambda, cliqueWeights);
%
%fprintf('\n\nCOOC Lambda:%d\tUnary:%.3f\tHigh:%.3f\tTotal Energy:%.3f\tTime:%.3f \n\n',params.lambda, uE, hE, mE, timeTaken);
%
%results{1,1}.inferenceType{1} = 'COOC';
%results{1,1}.labelings{1}.labeling = coocLabeling;
%results{1,1}.energy{1} = [uE pE hE mE];
%results{1,1}.timeTaken{1} = timeTaken;
%results{1,1}.lambda = params.lambda;
%results{1,1}.timeHOP{1} = 0;
%clusters_filename = strcat('clusters_mat/clusters_', configurationFile, '.mat');
clusters_filename = strcat('clusters_mat/', configurationFile(7: end - 4), '.mat');
save(clusters_filename, 'clusters');
metric_filename = strcat('metric_mat/', configurationFile(7: end - 4), '.mat');
save(metric_filename, 'metric');
%clear clusters metric
%load('clusters_mat/cluster.mat', 'clusters');
%load('metric_mat/metric.mat', 'metric');

clear uE pE hE mE

for k = 1:params.numTrees
    %% get labeling using Hier Pn-Potts
    tic;
    [hierLabeling, timeHOP] = hierarchicalPnPottsLabeling(clusters{k}, Dc, sG, hop, params.useCard, params.lambda, metric, cliqueWeights);
    timeTaken = toc;
    fprintf('Time taken = %.3f \n', timeTaken)
    [uE, pE, hE, mE] = compute_energy(sG, Dc, hop, hierLabeling, metric, params.lambda, cliqueWeights);
    
    fprintf('\nHier Lambda:%d\tUnary:%.3f\tHigh:%.3f\tTotal Energy:%.3f\tTime:%.3f\tTree:%d \n', params.lambda, uE, hE, mE, timeTaken, k);
    
    results{1,1}.inferenceType{k+1} = 'HierPn';
    results{1,1}.labelings{k+1}.labeling = hierLabeling;
    results{1,1}.energy{k+1} = [uE pE hE mE];
    results{1,1}.timeTaken{k+1} = timeTaken;
    results{1,1}.timeHOP{k+1} = timeHOP;
    
end

clear metric clusters

finalResult.params = params;
finalResult.results = results;
finalResult.clustersMetrics  = clustersMetrics;

% if(nargin>=1)
%     save(resultFileName,'finalResult');
% end
%% plot results
%plotGivenResults(finalResult);

end


function [numNodes, numLabels, Dc, sG, hop, cliqueWeights, truncationFactor, lambda] = getInfoConfFile(configurationFile)

confData = textread(configurationFile,'%f');
numNodes = int32(confData(1));
numLabels = int32(confData(2));
truncationFactor = confData(3);
lambda = confData(4);

index = 5;
Dc = confData(index:numNodes*numLabels+index-1);
Dc = reshape(Dc, [numLabels, numNodes]);
index = index + numNodes*numLabels;

numCliques = confData(index);
index = index+1;

cliqueWeights = zeros(numCliques,1);
hop = struct([]);

gamma = zeros(numLabels+1, 1); %just to complete the field.. won't be used
gamma(end) = 10;

for i = 1:numCliques
    
    numVar = confData(index);
    index = index+1;
    var = int32(confData(index:index+numVar-1));
    index = index+numVar;
    weight = confData(index);
    index = index + 1;
    
    hop(i).ind = var;
    hop(i).w = ones(1, length(var));
    hop(i).Q = 1; % to make it Pn-Potts model
    hop(i).gamma = gamma;
    
    cliqueWeights(i) = weight;
end

sG = sparse(double(numNodes), double(numNodes)); % won't be used

end
