function [cliqueWeights, sG] = getCliqueWeightsStereo(imLeftRgb,imName, hop, sigma)

numHops = length(hop);
[nRows, nCols, ~] = size(imLeftRgb);
cliqueWeights = zeros(numHops,1);
numNodes = nRows*nCols;
sG = sparse(numNodes,numNodes);

for i = 1:numHops    
    nodes = hop(i).ind;
    
    intensities = zeros(length(nodes), 3);
    for j = 1:length(nodes)
        [a,b] = ind2sub([nRows, nCols],nodes(j)); %it counts columnwise        
        intensities(j,:) = double(reshape(imLeftRgb(a,b,:), [3 1]));
    end
    
    if(length(nodes)==2) %pairwise clique        
        gradient = norm((intensities(1,:)-intensities(2,:)),2)^2;
        if(strcmp(imName, 'cones')) %cones (not mentioned)
            weight=1;
        elseif(strcmp(imName, 'teddy') && gradient<10*10*3) %teddy
            weight=3;
        elseif(strcmp(imName, 'tsukuba') && gradient<8*8*3) %tsukuba
            weight=2;
        elseif(strcmp(imName, 'venus') && gradient<=8*8*3) %venus (not mentioned)
            weight=1;
        else
            weight=1;
        end
        sG(nodes(1),nodes(2)) = double(weight);
        sG(nodes(2),nodes(1)) = sG(nodes(1),nodes(2));
    else %high-order cliques
        variance = norm(var( double(intensities) ), 1);
        weight = exp(-variance/sigma^2);
    end
    
    cliqueWeights(i) = weight;
    clear nodes
    
end
