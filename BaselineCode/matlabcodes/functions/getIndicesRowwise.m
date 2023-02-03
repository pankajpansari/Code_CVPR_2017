function [indices] = getIndices(startX, startY, wx, wy, sizeY)
indices = [];
for i = startX:startX+wx-1
    for j = startY:startY+wy-1
        temp = (i-1)*sizeY + j;
        indices = [indices, temp];
    end
end