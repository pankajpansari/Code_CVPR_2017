function [hop] = getHops(sizeX, sizeY, wx, wy, gamma, pairwise)
%indices starts with 1 (in C++ code this is being converted into 0-start)
counter = 0;
for i = 1:sizeX-wx+1
    for j = 1:sizeY-wy+1
        counter = counter + 1;        
        %[indices] = getIndices(i, j, wx, wy, sizeY);        
        [indices] = getIndicesColumnwise(i, j, wx, wy, sizeX);        
        hop(counter).ind = indices;
        hop(counter).w = ones(1, length(indices));
        hop(counter).Q = 1; % to make it Pn-Potts model
        hop(counter).gamma = gamma;
        
        
    end
end

%% Pairwise
if(pairwise)
    nodeNumbers = reshape(1:sizeX*sizeY, [sizeX sizeY]); %node numbers
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
end

end

% function [A] = getGridTypeAdjacencyMatrix(h , w)
% 
% A = sparse(h*w,h*w);
% lin = reshape(1:h*w, [h w]); %node numbers
% 
% % 4 connect graph
% A( sub2ind([h*w h*w], lin(:,1:end-1), lin(:,2:end) ) ) = 1;
% A( sub2ind([h*w h*w], lin(1:end-1,:), lin(2:end,:) ) ) = 1;
% 
% end



