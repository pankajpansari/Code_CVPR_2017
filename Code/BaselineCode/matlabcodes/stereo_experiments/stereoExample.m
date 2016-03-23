function [results] = stereoExample
stereoImName = 'venus'; 
%% some default parameters
if(strcmp(stereoImName, 'teddy'))
    lambda = 20;
    sigma = 100;
    truncation = 1;
    numTrees = 1;
    mra = 120;
elseif(strcmp(stereoImName, 'tsukuba'))
    lambda = 20;
    sigma = 100;
    truncation = 5;
    numTrees = 1;
    mra = 300;
else
    lambda = 20;
    sigma = 100;
    truncation = 5;
    numTrees = 1;
    mra = 200;
end

results = stereoExperimentsFunction(stereoImName, lambda, sigma, truncation, numTrees, mra);

end
