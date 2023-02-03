function createConfigFile(filename, lambda, truncation, Dc, hop, cliqueWeights)

fid = fopen(filename, 'w');
[numLabels, numNodes] = size(Dc);
fprintf(fid, '%d %d\n%f\n%f\n', numNodes, numLabels, truncation, lambda);

for i = 1:numNodes 
    for j = 1:numLabels
        fprintf(fid, '%f ',Dc(j,i));
    end
    fprintf(fid, '\n');
end

numCliques = length(hop);
fprintf(fid, '%d\n',numCliques);

for i = 1:numCliques    
    var = hop(i).ind;
    fprintf(fid, '%d ', length(var));  
    for j = 1:length(var)
        fprintf(fid, '%d ', var(j));
    end
    fprintf(fid, '\n%f\n', cliqueWeights(i));
end

fclose(fid);

numLines = 3+numNodes+1+2*numCliques;
fprintf('\n\tConfiguration file written:%s\t#lines:%d\n',filename, numLines);
