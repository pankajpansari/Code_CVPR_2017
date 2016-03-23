function V = getRandomMetrics(numLabels, potentialType, truncationFactor)

%numLabels = 10;
%potentialType = 1;
rng(10);
%rng('shuffle');

if(nargin<3)
    truncationFactor=numLabels;
end

%% Generate Pairwise Potentials
if(potentialType==1 || potentialType==2)       %truncated Linear/Quad
    V = get_truncated_lin_quad(numLabels, potentialType, truncationFactor);
elseif (potentialType == 3 || potentialType == 4) %random Metric/Semi-metric
    V = get_random_metric_semimetric(numLabels, potentialType);
end

end


function V = get_truncated_lin_quad(numLabels, potentialType, truncationFactor)

V = zeros(numLabels);

%r = a + (b-a).*rand(100,1);
if(potentialType == 1)  %truncated Linear
    smoothMax = (5-1)*rand(1) + 1;
else %truncated Quad
    smoothMax = (25-1)*rand(1) + 1;
end
lambda = 1;

if(nargin==3)
    smoothMax = truncationFactor;
end

for i = 1:numLabels
    for j = i:numLabels
        if(potentialType == 1)
            V(i,j) =  min(j-i, smoothMax)*lambda;
        else
            V(i,j) =  min((j-i)*(j-i), smoothMax)*lambda;
        end
        V(j,i) = V(i,j);
    end
end

end

function V = get_random_metric_semimetric(numLabels, potentialType)
%rng(10);
D = 9*rand(numLabels,numLabels)+1;
D = D - diag(diag(D));
D = (D + D')/2;

if(potentialType == 3)   %random Metric
    V = shortestPaths(D, numLabels);
else                     %random Semi-metric
    V = D;
end

end

function S = shortestPaths(D, numLabels)

oldS = D;
S = D;

for k=1:numLabels
    for i=1:numLabels
        for j=1:numLabels
            S(i,j) = min(oldS(i,j),oldS(i,k) + oldS(k,j));
        end
    end
    oldS = S;
end

end

% function write_matrix(matrix,fname)
% [rows, cols] = size(matrix);
% fid = fopen(fname,'w');
% for i = 1:rows
%     for j = 1:cols
%         fprintf(fid,'%f ',matrix(i,j));
%     end
%     fprintf(fid,'\n');
% end
% end

