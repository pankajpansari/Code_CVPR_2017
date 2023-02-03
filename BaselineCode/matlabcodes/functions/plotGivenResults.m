%setting: no |A|-1 multiplied, check with the aux of cooc,
function plotGivenResults(resultsAll)

results = [];
for i = 1:20
    a = load(sprintf('../newResults/resultsGivenCluster/results%d.mat',i-1));
    results = [results; a.finalResult.results];
    
end
params = a.finalResult.params;
    
params.lambda

numExp = length(results);
%results = resultsAll.results;
%params = resultsAll.params;

energyHier = zeros(params.numExp, length(params.lambda));
energyCOOC = zeros(params.numExp, length(params.lambda));

timeHier = zeros(params.numExp, length(params.lambda));
timeCOOC = zeros(params.numExp, length(params.lambda));

for i = 1:params.numExp
    for j = 1:length(params.lambda)
        for k = 1:params.numTrees
            energyTrees(k) = results{i,j}.energy{k+1}(end);
        end
        minEnergyTrees = min(energyTrees);
        
        energyHier(i,j) = minEnergyTrees;
        energyCOOC(i,j) = results{i,j}.energy{1}(end);
        
        %timeHier(i,j) = resultsAll{i,j}.energyHierPn.timeTaken;
        %timeCOOC(i,j) = resultsAll{i,j}.energyCOOC.timeTaken;
    end
    
end

figure, plot(mean(energyHier,1), '-*');
hold on;
plot(mean(energyCOOC,1), '-r*');
xlabel('lambdas [ 0,1,2,3,4,5,10,100,1000]'); ylabel(sprintf('mean energy for %d experiments', numExp)); legend('HierPn','COOC');

% figure, plot(mean(timeHier,1), '-*');
% hold on;
% plot(mean(timeCOOC,1), '-r*');
% xlabel('lambda [0, 1, 2, 3, 4, 5, 10, 1000]'); ylabel(sprintf('mean time (in secs) for %d experiments', numExp)); legend('HierPn','COOC');