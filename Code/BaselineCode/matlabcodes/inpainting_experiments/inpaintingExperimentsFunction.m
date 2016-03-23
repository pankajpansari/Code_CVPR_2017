function inpaintingExperimentsFunction(imName, lambda, sigma, truncation, numTrees, mra)
%inpaint_startup;

%% Cluster
%dataDir = '/home/pankaj/Max_of_convex_code_new/Code/Baseline_code/matlabcodes/inpainting_experiments/data/';
%resultDir = ['/home/pankaj/Max_of_convex_code_new/Code/Baseline_code/matlabcodes/inpainting_experiments/resultsInpainting/', imName, '/'];
%mkdir(resultDir)

%% PC
dataDir = './data/';
resultDir = ['./resultsInpainting/',imName, '/'];
mkdir(resultDir)

%% Parameters to play with
params.lambda = lambda;
params.truncationFactor = truncation;
params.sigma = sigma; % to compute the clique weights
params.numTrees = numTrees;
params.potentialType = 1;
params.useCard = 0;
params.pairwiseOnly = 0;
%%

params.numLabels = 256;
params.MinimumRegionArea = mra;
params.imName = imName;

im = double(imread([dataDir, imName, '-input.png']));
mask = imread([dataDir, imName, '-mask.png']); %required for on the fly hop comutation using mean shift

%% to run the code faster for debugging
%scale  = 0.3;
%im = double(imresize(im, scale, 'bilinear'));
%mask = double(imresize(mask, scale, 'bilinear'));

imMeanShift = cat(3,im, im, im);

%% Compute data costs
[params.nRows, params.nCols] = size(im);
params.sizeX = params.nRows;
params.sizeY = params.nCols;
params.numNodes = params.sizeX*params.sizeY;

Dc = dataCostInpainting(im, mask, params.numLabels);

%% Compute clique weights
% load precomputed hop (full image)
%hopPreComputed = load(params.hopName);
%hop = hopPreComputed.hop;

% compute hop on the fly using mean shift (use when the image is being
% resized)
hop = createHopsInpaintingImage(imMeanShift, mask, params.numLabels, params.pairwiseOnly, params.MinimumRegionArea);
cliqueWeights = getCliqueWeightsInpainting(im, hop, sigma);
sG = sparse(params.numNodes,params.numNodes);

%call function to create config file
%createConfigFile(['./configFiles/config_penguin_M', truncation, '_w', lambda, '.txt'], lambda, truncation, Dc, hop, cliqueWeights);

%% Generate random metrics and get the clusters
metric = getRandomMetrics(params.numLabels, params.potentialType, params.truncationFactor);

%% get the k random trees
clusters = cell(params.numTrees,1);
for k = 1:params.numTrees
    clusters{k} = anyMetric2treeMetricRandomFakcharoenphol(metric);
    length(clusters{k});
end

%% COOC Inference
tic;
[L, ~] = cooc_mex(sG, Dc, hop, metric, params.lambda(1), cliqueWeights);
coocLabeling = double(L+1);
timeTaken = toc;
[uE pE hE mE] = compute_energy(sG, Dc, hop, coocLabeling, metric, params.lambda(1), cliqueWeights);
energyCOOC = mE;
fprintf('\nCOOC Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken);

results.labelings{1} = coocLabeling;
results.energy{1} = [uE pE hE mE];
results.timeHOP{1} = 0;
results.timeTaken{1} = timeTaken;

coocLabeling = double(coocLabeling-1);

coccImageName = sprintf('%s/COOC_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);

finalcoocLabeling = reshape(coocLabeling, [params.sizeX, params.sizeY]);
imwrite(mat2gray(finalcoocLabeling),coccImageName);

%% Hier-Pn Potts Inference
mEbest = 1E100;
hierLabelingAll = cell(params.numTrees, 1);
energyFusion = zeros(params.numTrees, 1);
for k = 1:params.numTrees
    tic;
    [hierLabelingAll{k}.labeling, timeHOP] = hierarchicalPnPottsLabeling(clusters{k}, Dc, sG, hop, params.useCard, params.lambda(1), metric, cliqueWeights);
    timeTaken = toc;
    [uE pE hE mE] = compute_energy(sG, Dc, hop, hierLabelingAll{k}.labeling, metric, params.lambda(1), cliqueWeights);
    energyFusion(k) = mE;
    
    fprintf('Hier Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\tTree:%d\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken, k);
    
    results.labelings{k+1} = hierLabelingAll{k};
    results.energy{k+1} = [uE pE hE mE];
    results.timeHOP{k+1} = timeHOP;
    results.timeTaken{k+1} = timeTaken;
    
    if(mE<=mEbest)
        hierLabelingBestK = hierLabelingAll{k}.labeling;
        mEbest = mE;
    end
    
end
hierLabeling = double(hierLabelingBestK-1);

finalhierLabeling = reshape(hierLabeling, [params.sizeX, params.sizeY]);

%% Fusion
if(params.numTrees>1)
    [hierLabelingFused, finalEfused] = labelingFusion(hierLabelingAll, energyFusion, hop, Dc, metric, params.lambda(1), cliqueWeights, params.useCard);
    hierLabelingFused = double(hierLabelingFused-1);
    finalhierLabelingFused = reshape(hierLabelingFused, [params.sizeX, params.sizeY]);
    
    results.finalhierLabelingFusedTrees = finalhierLabelingFused;
    results.energyFusedTrees = finalEfused;
    
    fusedHierImageName = sprintf('%s/FUSED_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);
    imwrite(mat2gray(finalhierLabelingFused),fusedHierImageName);
end

%% save results
if(~exist(sprintf('%s',resultDir), 'dir'))
    mkdir resultDir;
end

%% save all the labelings and the parameters

results.finalcoocLabeling = finalcoocLabeling;
results.energyCOOC = energyCOOC;
results.finalhierLabelingBestTree = finalhierLabeling;
results.energyBestTree = mEbest;
results.params = params;
results.metric = metric;
results.hierClusters = clusters;
results.hop = hop;
results.cliqueWeights = cliqueWeights;

resultsFname = sprintf('%s/results_lambda%d_sigma%.4f_trunc%d_mra%d.mat', resultDir, params.lambda, params.sigma, params.truncationFactor, params.MinimumRegionArea);
save(resultsFname, 'results');

%% save images
hierImageName = sprintf('%s/HIER_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);

imwrite(mat2gray(finalhierLabeling),hierImageName);

