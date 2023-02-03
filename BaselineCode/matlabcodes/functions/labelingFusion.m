function [labelingNew, totalE] = labelingFusion(labelings, energy, hop, Dc, metric, lambda, cliqueWeights, useCard)

[energySorted, indices] = sort(energy, 'ascend');
labelingsSorted = labelings(indices);

numNodes = size(Dc,2);
numLabels = length(labelingsSorted); % now each child represents a label

%% get unary potentials of the new label subset (c1, c2, ..)
DcSub = zeros(numLabels, numNodes);
for l = 1:numLabels
    for k = 1:numNodes        
        DcSub(l,k) = Dc( labelingsSorted{l}.labeling(k) , k);
    end
end

%%
sG = sparse(numNodes, numNodes);

%% get new hops based on labelings
[hop] = hopWithGammaUsingLabelings(hop, labelingsSorted, metric, cliqueWeights, useCard);


%% initialize with the labeling having min energy (this will avoid bad local minimas)
initialLabeling = int32 (ones (1, numNodes)*indices(1));

%% inference (use pnPotts model for the inference)
[labeling, ~] = hierPn_mex(sG, DcSub, hop, lambda, initialLabeling);
%[labeling, ESub] = hierPn_mex(sG, DcSub, hop, lambda);
labeling = double(labeling+1);

%% final labeling
uniqueLabels = unique(labeling);

labelingNew = labeling;
if(length(uniqueLabels) == 1)    
    labelingNew = labelingsSorted{uniqueLabels}.labeling;
else
    for l = 1:length(uniqueLabels)        
        labelingNew(labeling == uniqueLabels(l)) = labelingsSorted{uniqueLabels(l)}.labeling(labeling == uniqueLabels(l));
    end
    
end

[~, ~, ~, totalE] = compute_energy(sG, Dc, hop, labelingNew, metric, lambda, cliqueWeights);
fprintf('\nMin energy before fusion:%f\nEnergy after fusion:%f\n',energySorted(1), totalE);

