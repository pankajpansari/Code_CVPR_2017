function visualize(file_type)
filename = 'confFileInpainting_houseL5_m1_M50.000000_wc50.000000_labeling.txt';
full_filename = strcat('../Data/configFiles/', filename);
file_type = 'house'
perform_visualization(full_filename, file_type);
%perform_visualization('/home/pankaj/Max_of_convex_code_new/Data/configFiles/confFileStereo_coneL4_m1_M5.000000_wc20.000000_labeling.txt', 'cones');

end

function visualize_inpainting(file_type)
filename = strcat('../Data/configFiles/confFileInpainting_', file_type, 'L5_m1_labeling.txt')
perform_visualization(filename, file_type);
pause(3);
filename = strlscat('../Data/configFiles/confFileInpainting_', file_type, 'L5_m5_labeling.txt')
perform_visualization(filename, file_type);
pause(3);
filename = strcat('../Data/configFiles/confFileInpainting_', file_type, 'L5_m10_labeling.txt')
perform_visualization(filename, file_type);
pause(3);
filename = strcat('../Data/configFiles/confFileInpainting_', file_type, 'L10_m1_labeling.txt')
perform_visualization(filename, file_type);
pause(3);
filename = strcat('../Data/configFiles/confFileInpainting_', file_type, 'L10_m5_labeling.txt')
perform_visualization(filename, file_type);
pause(3);
filename = strcat('../Data/configFiles/confFileInpainting_', file_type, 'L10_m10_labeling.txt')
perform_visualization(filename, file_type);
end

function perform_visualization(filename, file_type)
    fileID = fopen(filename, 'r');
    A = fscanf(fileID,'%d\n');
    fclose(fileID)
    
    if(strcmp(file_type,'small_house'))
    A_reshaped = reshape(A, [77 77]);
    end
    
    if(strcmp(file_type, 'house'))
    A_reshaped = reshape(A, [256 256]);
    end
    
    if(strcmp(file_type, 'penguin'))
    A_reshaped = reshape(A, [179 122]);
    end
    
    if(strcmp(file_type, 'teddy'))
    A_reshaped = reshape(A, [375 450]);
    end
    
    if(strcmp(file_type, 'tsukuba'))
    A_reshaped = reshape(A, [288 384]);
    end
    
     if(strcmp(file_type, 'venus'))
    A_reshaped = reshape(A, [383 434]);
     end
    
     if(strcmp(file_type, 'cones'))
    A_reshaped = reshape(A, [375 450]);
     end
    
    if(strcmp(file_type, 'house') | strcmp(file_type,'penguin'))
    A_reshaped_transpose = A_reshaped * 255/255;
    end
    
    if(strcmp(file_type,'teddy'))
    A_reshaped_transpose = A_reshaped * 255/60;
    end

    if(strcmp(file_type, 'tsukuba'))
    A_reshaped_transpose = A_reshaped * 255/16;
    end
    
     if(strcmp(file_type, 'venus'))
    A_reshaped_transpose = A_reshaped * 255/20;
     end
    
     if(strcmp(file_type, 'cones'))
    A_reshaped_transpose = A_reshaped * 255/60;
     end
    
        A_reshaped_transpose = uint8(A_reshaped_transpose);
    imshow(A_reshaped_transpose)
    image_filename = strcat('../Data/configFiles/', filename(1:end-4),'.png')
    imwrite(A_reshaped_transpose, image_filename);
end