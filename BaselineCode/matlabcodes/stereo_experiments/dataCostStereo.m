function [Dc] = dataCostStereo(imLeftRgb, imRightRgb, imName, numLabels)

%% Compute data costs for the stereo experiments
[nRows, nCols, ~] = size(imLeftRgb);

numNodes = nRows*nCols;
nodeNumbers = reshape(1:numNodes, [nRows nCols]); %node numbers
Dc = zeros(numLabels, numNodes);

worst_match = 3*255;

if(strcmp(imName, 'cones')) %cones (not given)
    maxsumdiff = 3*255;    
elseif(strcmp(imName, 'teddy')) %teddy
    maxsumdiff = 3*16;    
elseif(strcmp(imName, 'tsukuba')) %tsukuba
    maxsumdiff = 3*255;    
elseif(strcmp(imName, 'venus')) %venus
    maxsumdiff = 3*16;
    
end

badcost = min(worst_match, maxsumdiff);

for i = 1:nRows
    for j = 1:nCols
        index = nodeNumbers(i,j);
        for k = 1:numLabels
            jR = j-k+1;
            if(jR>0)
                iL = double(reshape(imLeftRgb(i,j,:), [3 1]));
                iR = double(reshape(imRightRgb(i,jR,:), [3 1]));
                
                %                 if(strcmp(imName, 'cones')) %cones
                %                     Dc(k, index) = norm((iL-iR),1);
                %                 elseif(strcmp(imName, 'teddy')) %teddy
                %                     Dc(k, index) = min( norm((iL-iR),1), 16);
                %                     %Dc(k, index) = norm((iL-iR),2);
                %                 elseif(strcmp(imName, 'tsukuba')) %tsukuba
                %                     Dc(k, index) = norm((iL-iR),1);
                %                 elseif(strcmp(imName, 'venus')) %venus
                %                     Dc(k, index) = min(norm((iL-iR),2)^2, 16);
                %                 end
                
                Dc(k, index) = min( norm((iL-iR),1), maxsumdiff);
                
            else
                Dc(k, index) = badcost;
            end
            
        end
        
    end
end