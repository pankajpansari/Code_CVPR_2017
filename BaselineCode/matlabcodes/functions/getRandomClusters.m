function [clusters, clusterPotentialMatrix] = getRandomClusters(numLabels)

%clear all; close all; clc;
%numLabels = 100;
%rng(10);
%% actualDiaCost range for the cluster node (note that this range will be updated as soon as a particular cluster is assigned the actualDiaCost=actualDiaCostEnd, in order
%% to maintain the metric property
rng('shuffle');
r=1;
actualDiaCostStart = 2;
actualDiaCostEnd = 5;

clusters{1}.numClusters = 1;
clusters{1}.cluster{1}.labels = 1:1:numLabels;
clusters{1}.cluster{1}.id = 1;
clusters{1}.cluster{1}.parents = [];

%% create the hierarchy randomly
level = 1;
numSingleton = 0;

while(numSingleton<numLabels)
    
    numClusters = clusters{level}.numClusters;
    childClustersID = 0;
    
    for i = 1:numClusters
        
        labelSet = clusters{level}.cluster{i}.labels;
        clusterID = clusters{level}.cluster{i}.id; % used as the parent ID for the kids so that they are not lost
        
        if(length(labelSet)>1)
            
            numChild = randi(length(labelSet), 1, 1); % randomly create some kids (more than one)
            if(numChild==1)
                numChild = 2;
            end
            %% only one level
            %numChild = length(labelSet); only one level down, all individual labels becomes the child
            
            %% deep tree
            if(numChild>2 && numLabels>2)
                numChild = 2;
            end
            
            
            clusters{level}.cluster{i}.numChild = numChild;
            
            totalLabels = length(labelSet);
            labelSetLeft = labelSet;
            %% assign labels to these child clusters
            for j = 1:numChild
                
                childClustersID = childClustersID+1;
                
                % randomly shuffle the label set of the parent
                randIndices = randperm(length(labelSetLeft));
                labelSetLeft = labelSetLeft(randIndices);
                
                % randomly choose a number so that remaning child has
                % atleast one label to assign with
                numLabelsUsed = randi( (totalLabels-numChild+j), 1, 1);
                if(j==numChild)
                    numLabelsUsed = totalLabels; %use all the remaining labels
                end
                totalLabels = totalLabels - numLabelsUsed;
                
                labelSubSet = labelSetLeft(1:numLabelsUsed);
                labelSetLeft(1:numLabelsUsed) =[];
                
                clusters{level}.cluster{i}.childID(j) = childClustersID;
                clusters{level}.cluster{i}.childClusters{j} = labelSubSet;
                
                clusters{level+1}.cluster{childClustersID}.labels = labelSubSet;
                clusters{level+1}.cluster{childClustersID}.id = childClustersID;
                clusters{level+1}.cluster{childClustersID}.parentID = clusterID;
                clusters{level+1}.cluster{childClustersID}.parentCluster = labelSet;
                
                if(length(labelSubSet)==1)
                    numSingleton = numSingleton+1;
                    clusters{level+1}.cluster{childClustersID}.numChild = 0;
                    clusters{level+1}.cluster{childClustersID}.childID = [];
                    clusters{level+1}.cluster{childClustersID}.childClusters = {};
                end
                
                
            end
            
        end
    end
    clusters{level+1}.numClusters = childClustersID;
    level = level+1;
    
end

%% Assign random actualDiaCosts to the clusters
maxactualDiaCost = 0;
numLevels = length(clusters);
actualDiaCostRange = actualDiaCostEnd-actualDiaCostStart;

for i = numLevels:-1:1
    numClusters = clusters{i}.numClusters;
    if(i<numLevels)
        actualDiaCostStart = r*maxactualDiaCost+1;
        actualDiaCostEnd = actualDiaCostStart+actualDiaCostRange;
        maxactualDiaCost = 0;
    end
    for j = 1:numClusters
        %actualDiaCost = actualDiaCostStart + (actualDiaCostEnd - actualDiaCostStart)*rand(1);
        actualDiaCost = randi([actualDiaCostStart, actualDiaCostEnd], 1, 1);
        if(length(clusters{i}.cluster{j}.labels)==1) %if singleton
            actualDiaCost = 0.0;
        end
        clusters{i}.cluster{j}.actualDiaCost = actualDiaCost;
        maxactualDiaCost = max(actualDiaCost, maxactualDiaCost);
    end
end
maxactualDiaCost;

%% compute potential matrix for cooc code
clusterPotentialMatrix = zeros(numLabels, numLabels);
for i = 1:numLevels
    for j = 1:clusters{i}.numClusters
        potential = clusters{i}.cluster{j}.actualDiaCost;
        if(clusters{i}.cluster{j}.numChild>1)
            for k = 1:clusters{i}.cluster{j}.numChild
                for l=k+1:clusters{i}.cluster{j}.numChild
                    childCluster1 = clusters{i}.cluster{j}.childClusters{k};
                    childCluster2 = clusters{i}.cluster{j}.childClusters{l};
                    
                    clusterPotentialMatrix(childCluster1, childCluster2) = potential;
                    clusterPotentialMatrix(childCluster2, childCluster1) = potential;
                    
                end
            end
        end
    end
end

clusters{1}.maxActualDiaCost = maxactualDiaCost;
clusters{1}.clusterPotentialMatrix = clusterPotentialMatrix;


