function [hopPotential] = getHOPpotential(uniqueLabels, metric)

% hopPotential = 0.0;
% tic; 
% for i = 1:length(uniqueLabels)
%     for j = i:length(uniqueLabels)
%         hopPotential = max( hopPotential, metric(uniqueLabels(i), uniqueLabels(j)) );
%     end
% end
% toc;

blockMat = metric(uniqueLabels, uniqueLabels);
hopPotential = max(blockMat(:));
