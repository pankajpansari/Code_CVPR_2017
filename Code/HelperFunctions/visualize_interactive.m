tic
while toc <= 100000
    pause(2)
    fileID = fopen('current_labeling.txt','r');
    A = fscanf(fileID,'%d\n');
    fclose(fileID)
    %for small house
    %A_reshaped = reshape(A, [77 77]);
    %for original house
    %A_reshaped = reshape(A, [256 256]);
    %for tedyy
    A_reshaped = reshape(A, [375 450]);
    %for tsukuba
    %A_reshaped = reshape(A, [288 384]);
        
    A_reshaped_transpose = A_reshaped*255/60;    
    A_reshaped_transpose = uint8(A_reshaped_transpose);
    imshow(A_reshaped_transpose)
end