function [hop] = createHopsInpaintingImage(imRgb, mask, nLabels, pairwiseOnly, mra)
%inpaint_startup;
%addpath('../../dependencies/meanShift/bagon/');

[nRows, nCols, ~] = size(imRgb);

sizeX = nRows;
sizeY = nCols;

nodeNumbers = reshape(1:sizeX*sizeY, [sizeX sizeY]); %node numbers

%% gamma -> just to complete the number of fields required by the mex file -> won't be used in the algo.
gamma = zeros(nLabels+1, 1);
gamma(end) = 10;

%% create pairwise hops
counter = 0;
for i = 1:sizeX
    for j = 1:sizeY-1
        counter = counter + 1;
        [indices] = [nodeNumbers(i,j), nodeNumbers(i,j+1)];
        hop(counter).ind = indices;
        hop(counter).w = ones(1, length(indices));
        hop(counter).Q = 1; % to make it Pn-Potts model
        hop(counter).gamma = gamma;
        
        if(length(indices)>2)
            fprintf('Warning: length(indices)>2');
        end
        
    end
end

for j = 1:sizeY
    for i = 1:sizeX-1
        counter = counter + 1;
        [indices] = [nodeNumbers(i,j), nodeNumbers(i+1,j)];
        hop(counter).ind = indices;
        hop(counter).w = ones(1, length(indices));
        hop(counter).Q = 1; % to make it Pn-Potts model
        hop(counter).gamma = gamma;
        
        if(length(indices)>2)
            fprintf('Warning: length(indices)>2');
        end
        
    end
end

%% create mean shift based hops
%% Bug: Penguin mask is 254 and house mask is 255.. so in ICCV experiments
% house only had pairwise cliques :-(.. resolve this issue
%Notice that the mean shift segments whic are not part of the blocked
%region are used as cliques..

if(~pairwiseOnly)
    args.MinimumRegionArea = mra;
    [fimage labels] = edison_wrapper(imRgb,@RGB2Luv, args);
    %imagesc(double(labels));
    numSegments = max(max(labels))+1; %starts with 0
    for i = 1:numSegments
        indices = nodeNumbers(labels==i-1);
        %if(sum(mask(indices)==254)) == length(indices)
        if(sum(mask(indices)~=0)) == length(indices) %a stupid bug fixed
        %if any(mask(indices)==1)
            counter = counter + 1;
            indices = nodeNumbers(labels==i-1);
            hop(counter).ind = indices;
            hop(counter).w = ones(1, length(indices));
            hop(counter).Q = 1; % to make it Pn-Potts model
            hop(counter).gamma = gamma;
        end
        
    end
    check = 0;
end






