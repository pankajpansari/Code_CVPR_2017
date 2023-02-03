% compile hierPn mex 
fprintf('\nCompiling hierPn');
cs = computer;
%cd /home/puneet/Projects/PhD/Codes/hierarchicalHOP/codes/allCodes/dependencies/hierPnPotts/
if ~isempty(strfind(cs,'64'))
    % 64-bit machine
    mex -O -DNDEBUG -largeArrayDims hierPn_mex.cpp 
    %mex -O -largeArrayDims hierPn_mex.cpp 
    
    % The char16_t is not set in clang (upgraded one) so we have to define
    % it
    % (http://stackoverflow.com/questions/22367516/mex-compile-error-unknown-type-name-char16-t)
    % Also, edit mexopts.sh (located in /Applications/MATLAB_R2013a.app/bin/), replace all the instances of 10.7 with 10.9
    % (starting from line 120, maci64).
    
    %mex -Dchar16_t=UINT16_T -O -DNDEBUG -largeArrayDims hierPn_mex.cpp 

else
    mex -O -DNDEBUG hierPn_mex.cpp
    %mex -O hierPn_mex.cpp
end
clear cs;
%cd /home/puneet/Projects/PhD/Codes/hierarchicalHOP/codes/allCodes/matlabcodes/
fprintf('\nhierPn compilation finished');
