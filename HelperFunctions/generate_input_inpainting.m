orig_im = imread('./Data/Inpainting/penguin-input.png');
mask_im = imread('./Data/Inpainting/penguin-mask.png');
seg_im = imread('./Data/Inpainting/segmimage.pnm');
seg_im = seg_im(: , :, 1);

size(orig_im)
% size(mask_im)
% size(seg_im)

segments = unique(seg_im);
nsegments = size(segments);
nsegments = nsegments(1)

size_im = size(orig_im) 
height = size_im(1)
width = size_im(2)
nvar = height * width
nlabels = max(max(orig_im))+1
M = 40
m = 1
sigma = 10000


unary = ones(height, width, 256, 'uint16');

file_path = pwd;
fileID = fopen('./Data/Inpainting/penguin_input.txt','w');
fprintf(fileID, '%d %lu\n', nvar, 256);
fprintf(fileID, '%d\n', M);
fprintf(fileID, '%d\n', m);
    
% Generate unary potentials
    
for i = 1:height
    for j = 1:width
        if mask_im(i, j) == 0
            for label = 1:256
                %fprintf(fileID, '%d ', 0);
                unary(i, j, label) = double(0) + 1;
            end
        else
            for label = 1:256
                %fprintf(fileID, '%d ', (orig_im(i, j) - label)^2);
                unary(i, j, label) = (abs(double(orig_im(i, j)) - double(label)))^2 + 1;
            end
        end
        fprintf(fileID, '%d ', unary(i, j, 1:255));
        fprintf(fileID, '%d\n', unary(i, j, 256));
    end
end

% distance function
fprintf(fileID, '1\n');

% number of cliques
fprintf(fileID, '%d\n', nsegments);

% Generate clique membership

%clique_members = zeros(
for i = 1:nsegments
    clique_members = find(seg_im' == segments(i));
    clique_members = clique_members - 1;
    length_clique = size(clique_members);
    length_clique = length_clique(1);
    fprintf(fileID, '%d ', length_clique);
    fprintf(fileID, '%d ',clique_members(1:(length_clique-1)));
    fprintf(fileID, '%d\n',clique_members(length_clique));
    [X, Y] = ind2sub([height, width], clique_members);
    intensity_clique = zeros(size(clique_members));
    count = 1;
    for j = 1:size(clique_members);
        intensity_clique(count) = orig_im(j);
        count = count + 1;
    end
    clique_variance = var(intensity_clique);
    clique_weight = exp(-(clique_variance/(sigma^2)));
    fprintf(fileID, '%d\n', clique_weight);
end

fclose(fileID);            
        


