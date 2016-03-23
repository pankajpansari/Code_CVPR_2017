function stereoAlphaExpansion


stereo_startup;
%% Parameters to play with
params.stereoImName = 'tsukuba';
params.lambda = 20;
params.truncationFactor = 2;
params.onlyAlpha = 1;
params.MinimumRegionArea = 200; %required for the mean shift
params.sigma = 100;

datasetPath = './stereo-pairs/';
%stereoPairs = {'cones'; 'teddy'; 'tsukuba'; 'venus'};

if(strcmp(params.stereoImName, 'cones')) %cones
    params.nDisp=60; % 0-59
    params.potentialType = 2;
elseif(strcmp(params.stereoImName, 'teddy')) %teddy
    params.nDisp=60; % 0-59
    params.potentialType = 1;
elseif(strcmp(params.stereoImName, 'tsukuba')) %tsukuba
    params.nDisp=16; % 0-15
    params.potentialType = 1;
elseif(strcmp(params.stereoImName, 'venus')) %venus
    params.nDisp=20; % 0-19
    params.potentialType = 2;
end

params.pairwiseOnly = 1;
params.numTrees = 1;
params.useCard=0;
params.numLabels = params.nDisp;
params.imNameLeft = [datasetPath, params.stereoImName, '/imL.png'];
params.imNameRight = [datasetPath, params.stereoImName, '/imR.png'];

imLeft = rgb2gray(imread(params.imNameLeft));
imRight = rgb2gray(imread(params.imNameRight));

imRightRgb = imread(params.imNameRight);
imLeftRgb = imread(params.imNameLeft); %required for on the fly hop comutation using mean shift

% scale  = 0.7;
% imRightRgb = imresize(imRightRgb, scale, 'nearest');
% imLeftRgb = imresize(imLeftRgb, scale, 'nearest');
% imRight = imresize(imRight, scale, 'nearest');
% imLeft = imresize(imLeft, scale, 'nearest');

% nRowsResized = 70;
% nColsResized = 70;
% imLeft = imresize(imLeft, [nRowsResized, nColsResized]);
% imRight = imresize(imRight, [nRowsResized, nColsResized]);
% imRightRgb = imresize(imRightRgb, [nRowsResized, nColsResized]);
% imLeftRgb = imresize(imLeftRgb, [nRowsResized, nColsResized]);

%% Generate random metrics and get the clusters
metric = getRandomMetrics(params.numLabels, params.potentialType, params.truncationFactor);

%% Compute data costs
[params.nRows, params.nCols, ~] = size(imLeftRgb);

params.sizeX = params.nRows;
params.sizeY = params.nCols;

params.numNodes = params.sizeX*params.sizeY;
Dc = dataCostStereo(imLeftRgb, imRightRgb, params.stereoImName, params.nDisp);

clear imRight

%% Compute clique weights
% load precomputed hop (full image)
%hopPreComputed = load(params.hopName);
%hop = hopPreComputed.hop;

% compute hop on the fly using mean shift (use when the image is being
% resized)
hop = createHopsStereoImage(imLeftRgb, params.nDisp, params.pairwiseOnly, params.MinimumRegionArea);
[cliqueWeights, sGNew] = getCliqueWeightsStereo(imLeftRgb,params.stereoImName, hop, params.sigma);
sG = sparse(params.numNodes,params.numNodes);

% numHops = length(hop);
% 
% sGNew = sparse(params.numNodes,params.numNodes);
% cliqueWeights = zeros(numHops,1);
% for i = 1:numHops
%     
%     nodes = hop(i).ind;
%     intensities = zeros(length(nodes),3);
%     for j = 1:length(nodes)
%         [a,b] = ind2sub([params.sizeX, params.sizeY],nodes(j)); %it counts columnwise
%         %intensities(j) = imLeft(a,b);
%         intensities(j,:) = double(reshape(imLeftRgb(a,b,:), [3 1]));
%         %intensities(j,:) = double((imLeft(a,b,:)));
%     end
%     gradient = norm((intensities(1,:)-intensities(2,:)),1);
%     if(strcmp(params.stereoImName, 'cones')) %cones (not mentioned)
%         weight=1;
%     elseif(strcmp(params.stereoImName, 'teddy') && gradient<10) %teddy
%         weight=3;
%     elseif(strcmp(params.stereoImName, 'tsukuba') && gradient<8) %tsukuba
%         weight=2;
%     elseif(strcmp(params.stereoImName, 'venus') && gradient<=8) %venus (not mentioned)
%         weight=1;
%     else
%         weight=1;
%     end
%     
%     sGNew(nodes(1), nodes(2)) = double(weight);
%     sGNew(nodes(2), nodes(1)) = sG(nodes(1), nodes(2));
%     
%     cliqueWeights(i) = weight;
%     clear nodes
%     
% end

%% Alpha expnasion
tic;
GCO_BuildLib(struct('Debug',1,'EnergyType','double'));
GCO_BuildLib(struct('Debug',1,'EnergyTermType','double'));
h = GCO_Create(params.numNodes, params.numLabels);
GCO_SetDataCost(h, Dc); %accepts int32
GCO_SetSmoothCost(h, metric);
GCO_SetNeighbors(h, params.lambda*sGNew);
GCO_Expansion(h);
alphaLabeling = double(GCO_GetLabeling(h));
timeTaken = toc;
%[E D S] = GCO_ComputeEnergy(h)
GCO_Delete(h);
[uE pE hE mE] = compute_energy(sG, Dc, hop, alphaLabeling, metric, params.lambda(1), cliqueWeights);
fprintf('\nAlpha Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken);

if(~params.onlyAlpha)
    
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
    [uE pE hE mE] = compute_energy_stereo(sG, Dc, hop, coocLabeling, metric, params.lambda(1), cliqueWeights);
    fprintf('\nCOOC Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken);
    
    results.labelings{1} = coocLabeling;
    results.energy{1} = [uE pE hE mE];
    
    %% Hier-Pn Potts Inference
    mEbest = 1E100;
    hierLabelingAll = cell(params.numTrees, 1);
    for k = 1:params.numTrees
        tic;
        hierLabelingAll{k} = hierarchicalPnPottsLabeling(clusters{k}, Dc, sG, hop, params.useCard, params.lambda(1), metric, cliqueWeights);
        timeTaken = toc;
        [uE pE hE mE] = compute_energy_stereo(sG, Dc, hop, hierLabelingAll{k}, metric, params.lambda(1), cliqueWeights);
        
        fprintf('Hier Exp:%d\tLambda:%d\tUnary:%.3f\tPair:%.3f\tHigh:%.3f\tTotal:%.3f\tTime:%.3f\tTree:%d\n',1, params.lambda(1), uE, pE, hE, mE, timeTaken, k);
        
        results.labelings{k+1} = hierLabelingAll{k};
        results.energy{k+1} = [uE pE hE mE];
        
        if(mE<=mEbest)
            hierLabelingBestK = hierLabelingAll{k};
            mEbest = mE;
        end
        
    end
    
    hierLabeling = double(hierLabelingBestK-1);
    coocLabeling = double(coocLabeling-1);
    
    
    finalcoocLabeling = reshape(coocLabeling, [params.sizeX, params.sizeY]);
    finalcoocLabeling = finalcoocLabeling*255/(params.nDisp-1);
    
    
    finalhierLabeling = reshape(hierLabeling, [params.sizeX, params.sizeY]);
    finalhierLabeling = finalhierLabeling*255/(params.nDisp-1);
    
    figure, imshow(mat2gray(finalcoocLabeling)), title(sprintf('COOC pair, lam:%d, tunc:%d',params.lambda, params.truncationFactor));
    figure, imshow(mat2gray(finalhierLabeling)), title(sprintf('HIER pair, lam:%d, tunc:%d',params.lambda, params.truncationFactor));
    
end

alphaLabeling = double(alphaLabeling -1);
finalalphaLabeling = reshape(alphaLabeling, [params.sizeX, params.sizeY]);
finalalphaLabeling = finalalphaLabeling*255/(params.nDisp-1);
figure, imshow(mat2gray(finalalphaLabeling)), title(sprintf('Alpha, lam:%d, tunc:%d',params.lambda, params.truncationFactor));
figure, imshow(imLeftRgb), title('Original Image: Left');


%% save results
% if(~exist(sprintf('%s',resultDir), 'dir'))
%     mkdir resultDir;
% end
%save all the labelings and the parameters
% results.finalcoocLabeling = finalcoocLabeling;
% results.finalhierLabeling = finalhierLabeling;
% results.finalalphaLabeling = finalalphaLabeling;
% results.params = params;

%resultsFname = sprintf('%s/results_lambda%d_sigma%.4f_trunc%d.mat', resultDir, params.lambda, params.sigma, params.truncationFactor);
%save(resultsFname, 'results');

%save images
%coccImageName = sprintf('%s/COOC_lambda%d_sigma%.4f_trunc%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor);
%hierImageName = sprintf('%s/HIER_lambda%d_sigma%.4f_trunc%d.png', resultDir, params.lambda, params.sigma, params.truncationFactor);

%imwrite(mat2gray(finalcoocLabeling),coccImageName);
%imwrite(mat2gray(finalhierLabeling),hierImageName);

