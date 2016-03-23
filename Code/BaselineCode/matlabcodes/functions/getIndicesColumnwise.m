function [indices] = getIndicesColumnwise(startX, startY, wx, wy, sizeX)
indices = [];
for i = startX:startX+wx-1
    for j = startY:startY+wy-1
        %temp = (i-1)*sizeY + j;
        temp = (j-1)*sizeX + i;
        indices = [indices, temp];
    end
end