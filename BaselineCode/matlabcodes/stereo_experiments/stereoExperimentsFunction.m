function results = stereoExperimentsFunction(stereoImName, lambda, sigma, truncation, numTrees, mra)

%% cluster (hard code the path because the relative path is different)
%datasetPath = '/home/users/pukumar/codes/hierPn/codes_new/allCodes/matlabcodes/stereo_experiments/stereo-pairs/';
%hopPath = '/home/users/pukumar/codes/hierPn/codes_new/allCodes/matlabcodes/stereo_experiments/stereo_hops/';
%%stereoPairs = {'cones'; 'teddy'; 'tsukuba'; 'venus'};
%resultDir = ['/home/users/pukumar/codes/hierPn/codes_new/allCodes/matlabcodes/stereo_experiments/results/', stereoImName, '/'];
%mkdir(resultDir)


%% PC
datasetPath = './stereo-pairs/';
hopPath = './stereo_hops/';
resultDir = ['./resultsFused/', stereoImName, '/'];
mkdir(resultDir)
%
%%stereoPairs = {'cones'; 'teddy'; 'tsukuba'; 'venus'};

if(strcmp(stereoImName, 'cones')) %cones
    params.nDisp=60; % 0-59
    params.potentialType = 2;
elseif(strcmp(stereoImName, 'teddy')) %teddy
    params.nDisp=60; % 0-59
    params.potentialType = 1;
elseif(strcmp(stereoImName, 'tsukuba')) %tsukuba
    params.nDisp=16; % 0-15
    params.potentialType = 1;
elseif(strcmp(stereoImName, 'venus')) %venus
    params.nDisp=20; % 0-19
    params.potentialType = 2;
end

%% Parameters to play with
params.truncationFactor = truncation;
params.sigma = sigma; % to compute the clique weights
params.lambda = lambda;
params.numTrees = numTrees;
params.useCard = 0;
params.pairwiseOnly = 0;
%%

params.numLabels = params.nDisp;
params.MinimumRegionArea = mra;  %required for the mean shift
params.stereoImName = stereoImName;
params.hopName = [hopPath, stereoImName, '_hop.mat'];
params.stereoImNameLeft = [datasetPath, stereoImName, '/imL.png'];
params.stereoImNameRight = [datasetPath, stereoImName, '/imR.png'];

imLeft = rgb2gray(imread(params.stereoImNameLeft));
imRight = rgb2gray(imread(params.stereoImNameRight));

imRightRgb = imread(params.stereoImNameRight);
imLeftRgb = imread(params.stereoImNameLeft); %required for on the fly hop comutation using mean shift

% nRowsResized = 70;
% nColsResized = 70;
% imLeft = imresize(imLeft, [nRowsResized, nColsResized]);
% imRight = imresize(imRight, [nRowsResized, nColsResized]);
% imRightRgb = imresize(imRightRgb, [nRowsResized, nColsResized]);
% imLeftRgb = imresize(imLeftRgb, [nRowsResized, nColsResized]);

%% Compute data costs
[params.nRows, params.nCols, ~] = size(imLeftRgb);

params.sizeX = params.nRows;
params.sizeY = params.nCols;
params.numNodes = params.sizeX*params.sizeY;

Dc = dataCostStereo(imLeftRgb, imRightRgb, params.stereoImName, params.nDisp);

%% Get the hops and compute clique weights
% load precomputed hop (full image)
hopPreComputed = load(params.hopName);
hop = hopPreComputed.hop;

% compute hop on the fly using mean shift (use when the image is being
% resized)
%hop = createHopsStereoImage(imLeftRgb, params.nDisp, params.pairwiseOnly, params.MinimumRegionArea);
cliqueWeights = getCliqueWeightsStereo(imLeftRgb,stereoImName, hop, params.sigma);
sG = sparse(params.numNodes, params.numNodes); 

%call function to create config file
createConfigFile(['./configFiles/config_', stereoImName, '_M', truncation, '_w', lambda, '.txt'], lambda, truncation, Dc, hop, cliqueWeights);

%% Generate random metrics and get the clusters
metric = getRandomMetrics(params.numLabels, params.potentialType, params.truncationFactor);

%% get the k random trees
clusters = cell(params.numTrees,1);
for k = 1:params.numTrees
    clusters{k} = anyMetric2treeMetricRandomFakcharoenphol(metric);
    length(clusters{k});
end

fprintf('COOC starting\n')
%% COOC Inference
tic;
[L, ~] = cooc_mex(sG, Dc, hop, metric, params.lambda(1), cliqueWeights);
coocLabeling = double(L+1);
timeTaken = toc;
[uE pE hE mE] = compute_energy(sG, Dc, hop, coocLabeling, metric, params.lambda(1), cliqueWeights);
energyCOOC = mE;
fprintf('\nCOOC Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken);

coocLabeling = double(coocLabeling-1);

finalcoocLabeling = reshape(coocLabeling, [params.sizeX, params.sizeY]);
finalcoocLabeling = finalcoocLabeling*255/(params.nDisp-1);


coccImageName = sprintf('%s/COOC_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);

results.labelings{1} = coocLabeling;
results.energy{1} = [uE pE hE mE];
results.timeHOP{1} = 0;
results.timeTaken{1} = timeTaken;

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
    
    results.labelings{k+1} = hierLabelingAll{k}.labeling;
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
finalhierLabeling = finalhierLabeling*255/(params.nDisp-1);

%% Fusion
[hierLabelingFused, finalEfused] = labelingFusion(hierLabelingAll, energyFusion, hop, Dc, metric, params.lambda(1), cliqueWeights, params.useCard);
hierLabelingFused = double(hierLabelingFused-1);
finalhierLabelingFused = reshape(hierLabelingFused, [params.sizeX, params.sizeY]);

%% save results
if(~exist(sprintf('%s',resultDir), 'dir'))
    mkdir resultDir;
end

%% save all the labelings and the parameters
results.finalcoocLabeling = finalcoocLabeling;
results.finalhierLabelingBestTree = finalhierLabeling;
results.finalhierLabelingFusedTrees = finalhierLabelingFused;
results.energyBestTree = mEbest;
results.energyFusedTrees = finalEfused;
results.energyCOOC = energyCOOC;
results.params = params;
results.metric = metric;
results.hierClusters = clusters;
results.hop = hop;
results.cliqueWeights = cliqueWeights;

resultsFname = sprintf('%s/results_lambda%d_sigma%.4f_trunc%d_mra%d.mat', resultDir, params.lambda, params.sigma, params.truncationFactor, params.MinimumRegionArea);
save(resultsFname, 'results');

%% save images
hierImageName = sprintf('%s/HIER_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);
fusedHierImageName = sprintf('%s/FUSED_lambda%d_sigma%.4f_trunc%d_mra%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor,params.MinimumRegionArea);

imwrite(mat2gray(finalhierLabeling),hierImageName);
imwrite(mat2gray(finalhierLabelingFused),fusedHierImageName);

