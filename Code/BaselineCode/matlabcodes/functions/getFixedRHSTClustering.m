function [clusters, clusterPotentialMatrix] = getFixedRHSTClustering(K, numLabels)

numLevels = 4;

clusters{1}.numClusters = 1;
clusters{1}.cluster{1}.labels = [1, 2 , 3, 4, 5];
clusters{1}.cluster{1}.cost = 8*K;
clusters{1}.cluster{1}.id = 1;
clusters{1}.cluster{1}.numChild = 2;
clusters{1}.cluster{1}.childID = [1, 2]; %childID
clusters{1}.cluster{1}.parents = [];
clusters{1}.cluster{1}.childClusters = {[1, 3, 4], [2, 5]};


clusters{2}.numClusters = 2;
clusters{2}.cluster{1}.labels = [1, 3 , 4];
clusters{2}.cluster{1}.cost = 4*K;
clusters{2}.cluster{1}.id = 1;
clusters{2}.cluster{1}.numChild = 2;
clusters{2}.cluster{1}.childID = [1, 2];
clusters{2}.cluster{1}.parents = [1, 2, 3, 4];
clusters{2}.cluster{1}.childClusters = {[3, 4], [1]};

clusters{2}.cluster{2}.labels = [2,5];
clusters{2}.cluster{2}.cost = 4*K;
clusters{2}.cluster{2}.id = 2;
clusters{2}.cluster{2}.numChild = 2;
clusters{2}.cluster{2}.childID = [3, 4];
clusters{2}.cluster{2}.parents = [1, 2, 3, 4];
clusters{2}.cluster{2}.childClusters = {[2], [5]};

clusters{3}.numClusters = 4;
clusters{3}.cluster{1}.labels = [3, 4];
clusters{3}.cluster{1}.cost = 2*K;
clusters{3}.cluster{1}.id = 1;
clusters{3}.cluster{1}.numChild = 2;
clusters{3}.cluster{1}.childID = [1 2];
clusters{3}.cluster{1}.parents = [1, 3, 4];
clusters{3}.cluster{1}.childClusters = {[3], [4]};

clusters{3}.cluster{2}.labels = [1];
clusters{3}.cluster{2}.cost = 0;%2*K; % should be 0
clusters{3}.cluster{2}.id = 2;
clusters{3}.cluster{2}.numChild = 0;
clusters{3}.cluster{2}.childID = [];
clusters{3}.cluster{2}.parents = [1, 3, 4];
clusters{3}.cluster{2}.childClusters = {};

clusters{3}.cluster{3}.labels = [2];
clusters{3}.cluster{3}.cost = 0;%2*K; % should be 0
clusters{3}.cluster{3}.id = 3;
clusters{3}.cluster{3}.numChild = 0;
clusters{3}.cluster{3}.childID = [];
clusters{3}.cluster{3}.parents = [2, 5];
clusters{3}.cluster{3}.childClusters = {};

clusters{3}.cluster{4}.labels = 5;
clusters{3}.cluster{4}.cost = 0;%2*K; % should be 0
clusters{3}.cluster{4}.id = 4;
clusters{3}.cluster{4}.numChild = 0;
clusters{3}.cluster{4}.childID = [];
clusters{3}.cluster{4}.parents = [2, 5];
clusters{3}.cluster{4}.childClusters = {};

clusters{4}.numClusters = 2;
clusters{4}.cluster{1}.labels = [3];
clusters{4}.cluster{1}.cost = 0;
clusters{4}.cluster{1}.id = 1;
clusters{4}.cluster{1}.numChild = 0;
clusters{4}.cluster{1}.childID = [];
clusters{4}.cluster{1}.parents = [3,4];
clusters{4}.cluster{1}.childClusters = {};

clusters{4}.cluster{2}.labels = [4];
clusters{4}.cluster{2}.cost = 0;
clusters{4}.cluster{2}.id = 2;
clusters{4}.cluster{2}.numChild = 0;
clusters{4}.cluster{2}.childID = [];
clusters{4}.cluster{2}.parents = [3,4];
clusters{4}.cluster{2}.childClusters = {};



%% compute potential matrix for cooc code
clusterPotentialMatrix = zeros(numLabels, numLabels);
for i = 1:numLevels-1
    for j = 1:clusters{i}.numClusters
        potential = clusters{i}.cluster{j}.cost;
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


end