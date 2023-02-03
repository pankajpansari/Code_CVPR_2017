function [results] = inpaintingExample
imName = 'house';

%% some default parameters
if(strcmp(imName, 'penguin'))
    lambda = 40;
    sigma = 10000;
    truncation = 40;
    numTrees = 1;
    mra = 200;
elseif(strcmp(imName, 'house'))
    lambda = 50;
    sigma = 1000;
    truncation = 50;
    numTrees = 1;
    mra = 300;
else
    lambda = 20;
    sigma = 100;
    truncation = 5;
    numTrees = 1;
    mra = 200;
end

inpaintingExperimentsFunction(imName, lambda, sigma, truncation, numTrees, mra);

end
