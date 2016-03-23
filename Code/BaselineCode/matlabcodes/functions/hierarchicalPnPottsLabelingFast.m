function [finalLabeling, tHOP] = hierarchicalPnPottsLabelingFast(clusters, Dc, sG, hop,  useCard, lambda, metric, cliqueWeights)
numNodes = size(Dc, 2);
numLevels = length(clusters);
tHOP = 0;
for i = numLevels:-1:1
    for j = 1:1:clusters{i}.numClusters
        
        if( clusters{i}.cluster{j}.numChild == 0 ) % trivial labeling                  
            clusters{i}.cluster{j}.labeling = double ( clusters{i}.cluster{j}.labels(1) * ones (1, numNodes) );
            
            
           
        elseif ( clusters{i}.cluster{j}.numChild == 1 ) % again trivial, same labeling as that of the child (this case shouldn't happen, check)
            childID = clusters{i}.cluster{j}.childID(1); % only one child
            clusters{i}.cluster{j}.labeling = clusters{i+1}.cluster{childID}.labeling;
           
        else % if more than one child
            
            % create gammas using the labelings of the children at (i+1)^th level
            numChild = clusters{i}.cluster{j}.numChild;
            numLabelsSub = numChild; % now each child represents a label            
            
            % get unary potentials of the new label subset (c1, c2, ..)
            DcSub = zeros(numLabelsSub, numNodes); 
            for l = 1:numLabelsSub
                childID = clusters{i}.cluster{j}.childID(l);
                for k = 1:numNodes                    
                    labelTemp = clusters{i+1}.cluster{childID}.labeling(k); %label given to node k by the child of l^th cluster at (i+1)^th level
                    DcSub(l,k) = Dc( labelTemp , k);
                end
            end
            
            %% create different gammas for each clique based on their labels (very slow)
            tStart = tic;
            labelings = cell(numChild, 1);
            for l = 1:numChild
                childID = clusters{i}.cluster{j}.childID(l);                                
                labelings{l}.labeling = clusters{i+1}.cluster{childID}.labeling;
            end
            hopSub = hopWithGammaUsingLabelings(hop, labelings, metric, cliqueWeights, useCard);
            tHOP = tHOP + toc(tStart);
            [labeling, ESub] = hierPn_mex(sG, DcSub, hopSub, lambda);
            labeling = double(labeling+1);
            
            % final labeling
            uniqueLabels = unique(labeling);
            
            labelingNew = labeling;
            if(length(uniqueLabels) == 1)
                childID = clusters{i}.cluster{j}.childID(uniqueLabels);                
                labelingNew = clusters{i+1}.cluster{childID}.labeling;
            else
                for l = 1:length(uniqueLabels)
                    childID = clusters{i}.cluster{j}.childID(uniqueLabels(l));                    
                    labelingNew(labeling == uniqueLabels(l)) = clusters{i+1}.cluster{childID}.labeling(labeling == uniqueLabels(l));
                end
                
            end            
            clusters{i}.cluster{j}.labeling = labelingNew; %final labeling 
          
        end
        
        %numLabels = length(clusters{1}.cluster{1}.labels);
        %gamma = [ones(1, numLabels), 100]; % won't be used while computing the hop energy
        %hop = hopIndices2hop(sizeX, sizeY, wx, wy, hopIndices, gamma);
        
        
    end
end
tHOP;
finalLabeling = clusters{1}.cluster{1}.labeling;



            %gammaSub(l+1) = (cardCluster - 1) * clusters{i}.cluster{j}.cost;
            %numLabelsSub
            %gammaSub(l+1) = 1000000;
            
%             % create new gammas based on the number of children and the cost they have paid 
%             cardCluster = 2;
%             for l = 1:numLabelsSub               
%                 childID = clusters{i}.cluster{j}.child(l);
%                 if(useCard)
%                     %cardCluster =
%                     %length(clusters{i+1}.cluster{childID}.labels); % check
%                   
%                     cardCluster = clusters{i+1}.cluster{j}.numChild; %check
%                 end
%                 gammaSub(l) = (cardCluster - 1) * clusters{i+1}.cluster{childID}.cost;
%             end
%             if(useCard)
%                 %cardCluster = length(clusters{i}.cluster{j}.labels); %check
%                 cardCluster = clusters{i}.cluster{j}.numChild; %check
%                 
%             end
%             gammaSub(l+1) = (cardCluster - 1) * clusters{i}.cluster{j}.cost;



            
            % create new gammas based on the number of children and the cost they have paid 
%             cardCluster = 2;
%             gammaSub = zeros(1, numLabelsSub+1);
%             for l = 1:numLabelsSub               
%                 childID = clusters{i}.cluster{j}.childID(l);                
%                 labelSetChild = unique( clusters{i+1}.cluster{childID}.labeling );   
%                 gammaLabelingChild = getHOPpotential(labelSetChild, metric);
%                 
%                 if(useCard) 
%                     cardCluster = length(labelSetChild);
%                 end                
%                 gammaSub(l) = (cardCluster - 1) * gammaLabelingChild;                
%             end
%             if(useCard)
%                 cardCluster = length(clusters{i}.cluster{j}.labels); %check
%                 %cardCluster = clusters{i}.cluster{j}.numChild; %check
%                 
%             end
%             gammaSub(l+1) = (cardCluster - 1) * clusters{i}.cluster{j}.actualDiaCost;
%             
%             % update hopIndices structure using the new gammas
%             hopSub = hopIndices2hop(sizeX, sizeY, wx, wy, hopIndices, gammaSub);
