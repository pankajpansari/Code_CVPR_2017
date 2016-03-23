curPath = pwd;

cd(paths.coocPath);
compile_cooc;

cd(paths.hierPnPath);
compile_hierPn;

cd(paths.meanShiftPath);
compile_edison_wrapper; %Mean shift wrapper to generate the cliques

cd(curPath);

fprintf('\n\tAll the compilation has been finished\n');
