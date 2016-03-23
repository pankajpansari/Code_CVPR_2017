fileID = fopen('inpainting_output.txt','r');
A = fscanf(fileID,'%d\n');
fclose(fileID)
A_reshaped = reshape(A, [122 179]);
A_reshaped_transpose = transpose(A_reshaped);
A_reshaped_transpose = uint8(A_reshaped_transpose);
imshow(A_reshaped_transpose)
