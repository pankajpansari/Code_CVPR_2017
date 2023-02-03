function [hop] = hopWithGammaUsingLabelings(hop, labelings, labelMetric, cliqueWeights, useCard)

numLabelings = length(labelings);
numHops = length(hop);

for i = 1:numHops
    
    finalSet = [];
    gamma = zeros(1, numLabelings+1);
    for l = 1:numLabelings
        %uniqueLabels = unique( labelings{l}.labeling(hop(i).ind) ); %very time consuming
        uniqueLabels = labelings{l}.labeling(hop(i).ind); 
        gamma(l) = getHOPpotential(uniqueLabels, labelMetric); %time consuming
        finalSet = [finalSet, uniqueLabels];
    end
    finalSet = unique(finalSet);
    gamma(numLabelings+1) = getHOPpotential(finalSet, labelMetric);
    
    if(useCard)
        gamma(numLabelings+1) = (numLabelings-1)*gamma(numLabelings+1); %TODO: check this???
    end            
    hop(i).gamma = cliqueWeights(i)*gamma; %note that each clique will have different gammas
%     hop(counter).ind =  hop(counter).ind;
%     hop(counter).w =  hop(counter).w;
%     hop(counter).Q = hop(counter).Q;
end
