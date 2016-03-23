function [Dc] = dataCostInpainting(im, mask, numLabels)

[nRows, nCols] = size(im);
numNodes = nRows*nCols;
nodeNumbers = reshape(1:numNodes, [nRows nCols]); %node numbers
Dc = zeros(numLabels, numNodes);

for i = 1:nRows
    for j = 1:nCols
        index = nodeNumbers(i,j);
        for k = 1:numLabels
            if(mask(i,j)==0)
                Dc(k, index) = 0;
            else
                Dc(k, index) = double((im(i,j)-k-1)^2);
            end            
        end
        
    end
end
