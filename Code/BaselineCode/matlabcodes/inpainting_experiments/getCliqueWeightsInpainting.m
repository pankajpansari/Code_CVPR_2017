function cliqueWeights = getCliqueWeightsInpainting(im, hop, sigma)

numHops = length(hop);
[nRows, nCols, ~] = size(im);
cliqueWeights = zeros(numHops,1);

for i = 1:numHops
    
    nodes = hop(i).ind;
    intensities = zeros(length(nodes), 1);
    for j = 1:length(nodes)
        [a,b] = ind2sub([nRows, nCols],nodes(j)); %it counts columnwise        
        intensities(j,:) = double(im(a,b));
    end
    
    if(length(nodes)==2) %pairwise clique        
        %gradient = norm((intensities(1,:)-intensities(2,:)),1);
        weight = 1.0;  
    else %high-order cliques
        variance = norm(var( double(intensities) ), 1);
        weight = exp(-variance/sigma^2);  
    end
    
    cliqueWeights(i) = weight;
    clear nodes
    
end