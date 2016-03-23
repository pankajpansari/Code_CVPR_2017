fprintf('\nCompiling cooc');
cs = computer;
%cd /home/puneet/Projects/PhD/Codes/hierarchicalHOP/codes/allCodes/dependencies/cooccurrence/
if ~isempty(strfind(cs,'64'))
    % 64-bit machine
    mex -g -largeArrayDims cooc_mex.cpp 
    
    % The char16_t is not set in clang (upgraded one) so we have to define
    % it
    % (http://stackoverflow.com/questions/22367516/mex-compile-error-unknown-type-name-char16-t)
    % Also, edit mexopts.sh (located in /Applications/MATLAB_R2013a.app/bin/), replace all the instances of 10.7 with 10.9
    % (starting from line 120, maci64).
    
    %mex -Dchar16_t=UINT16_T -O -DNDEBUG -largeArrayDims robustpn_mex.cpp 

else
    mex -g cooc_mex.cpp 
end
clear cs;
%cd /home/puneet/Projects/PhD/Codes/hierarchicalHOP/codes/allCodes/matlabcodes/
fprintf('\ncooc compilation finished');
