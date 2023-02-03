
function [clusters] = anyMetric2treeMetricRandomFakcharoenphol(givenMetric)
%function [treeMetric clusters] = anyMetric2treeMetricRandomUpdated(givenMetric)
%%Condition: min dij > 1 (i \neq j)         --- IMPORTANT

rng('shuffle');
%rng(10);
origMetric = givenMetric;

%% make sure that d(i,j)>1
temp = givenMetric;
temp(temp == 0) = Inf;
minDistance = min(min(temp));
if(minDistance<1)
    givenMetric = (2*givenMetric/minDistance);
end

%% compute the diameter of the given metric space
Delta = max(givenMetric(:));
del = ceil(log(Delta)/log(2));
%numLevels = del; 

%% Choose a random permutation of the vertices (labels in our case)
numVertices = size(givenMetric,1);
Vrand = randperm(numVertices);
%Vrand = 1:1:numVertices;

%% choose beta randomly between [1, 2] from p(x) = 1/xln2
beta = 1.0001 + (1.9999 - 1.0001)*rand(1,1);
%beta = 1.5;

%% clusters
clusters{1}.numClusters = 1;
clusters{1}.cluster{1}.labels = Vrand;
clusters{1}.cluster{1}.id = 1;
clusters{1}.cluster{1}.parentID = [];
clusters{1}.cluster{1}.parentCluster = [];
clusters{1}.cluster{1}.actualDiaCost = max(max(origMetric(:)));
%clusters{1}.rHSTedgeLength(1) = max(max(origMetric(:)))/2.0;

numSingletons = 0;
i = del-1;
level = 1;

while(numSingletons < numVertices)  
    beta_i = 2^(i-1)*beta;    
    numClusters = 0;
    for c = 1:clusters{level}.numClusters
        partitioningSet = clusters{level}.cluster{c}.labels;
        partitioningSetOriginal = partitioningSet;
        numChild = 0;
        if(length(partitioningSet) > 1)
            for v = 1:numVertices
                if(isempty(partitioningSet))
                    break;
                end
                vRand = Vrand(v);
                ballElements = ball(vRand, beta_i, givenMetric);
                commonElements = intersect(ballElements, partitioningSet);
                if(~isempty(commonElements))
                    numClusters = numClusters + 1;
                    numChild = numChild +1;
                    
                    clusters{level}.cluster{c}.childID(numChild) = numClusters;
                    clusters{level}.cluster{c}.childClusters{numChild} = commonElements;
                    clusters{level}.cluster{c}.numChild = numChild;
                    
                    clusters{level+1}.cluster{numClusters}.labels = commonElements;
                    clusters{level+1}.cluster{numClusters}.id = numClusters;
                    clusters{level+1}.cluster{numClusters}.parentID = c;
                    clusters{level+1}.cluster{numClusters}.parentCluster = partitioningSetOriginal;
                    clusters{level+1}.cluster{numClusters}.actualDiaCost = max(max(origMetric(commonElements, commonElements)));
                    
                    if(length(commonElements)==1)
                        numSingletons = numSingletons+1;
                        clusters{level+1}.cluster{numClusters}.numChild = 0;
                        clusters{level+1}.cluster{numClusters}.childID = [];
                        clusters{level+1}.cluster{numClusters}.childClusters = {};
                    end
                    
                    partitioningSet = setdiff(partitioningSet, commonElements);
                    
                end
                
            end
        else
            %numSingletons = numSingletons+1;
        end
        clusters{level+1}.numClusters = numClusters;
    end
    level = level+1;
    i = i-1;
end

checkClusterFields(clusters)
check = 0;
%cluster2finalCluster(clusters, givenMetric, origMetric);

% singletons to tree
%treeMetric = approximatedTreeMetric(numVertices,singletonAtLevel, splittedAtLevel);
%if(minDistance<1)
%    treeMetric = treeMetric*minDistance/2; %% Nullify the condition: min dij > 1 (i \neq j)
%end
%treeMetric = treeMetric+treeMetric';

end

function checkClusterFields(clusters)
for i = 1:length(clusters)
    for j = 1:clusters{i}.numClusters
        if(isfield(clusters{i}.cluster{j}, 'numChild'))
        else
            fprintf('\nnumChild field does not exist in level:%d\tcluster:%d', i, j);
        end        
    end
end
end

function [ballElements] = ball(vertex, r, dGiven)

ballElements = find(dGiven(vertex,:)<r);

end


function [distance] = distanceBetweenNodes(iNodeLevel, jNodeLevel)
%sum of GP: ar^(i+1) + ar^(i-2) ... + ar^(j) -> ar^(i+1) a(r^(j-i) - 1)/(r-1)

higherLevel = max(iNodeLevel, jNodeLevel);
lowerLevel = min(iNodeLevel, jNodeLevel);
distance = 2^(lowerLevel+1)*(2^(higherLevel-lowerLevel) - 1);

end

function [dij] = distanceBetweenLeaves(iNodeLevel, jNodeLevel, splitLevel)

dij = distanceBetweenNodes(iNodeLevel, splitLevel) + distanceBetweenNodes(jNodeLevel, splitLevel);

end

function [dTree] = approximatedTreeMetric(numVertices, singletonAtLevel, splittedAtLevel)

dTree = zeros(numVertices, numVertices);
for i = 1:numVertices
    iLevel = singletonAtLevel(i);
    for j = i+1:numVertices
        jLevel = singletonAtLevel(j);
        splitLevel = max(splittedAtLevel(i,j), splittedAtLevel(j,i)); %stores only once, so ignore zero
        dTree(i,j) = distanceBetweenLeaves(iLevel, jLevel, splitLevel);
        
    end
    
end
end




