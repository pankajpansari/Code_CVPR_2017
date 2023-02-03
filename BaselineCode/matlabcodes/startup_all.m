%parentDir = '/Users/puneet/work/phd/codes/hierarchicalPnPotts/bitbucket/hierarchicalpnpotts/';
parentDir = fullfile(pwd, '../');
paths.parentDir = parentDir;

%% Dependencies (mexed codes)
paths.coocPath = [parentDir, 'dependencies/cooccurrence'];
paths.hierPnPath = [parentDir, 'dependencies/hierPnPotts'];
paths.labelCostPath = [parentDir, 'dependencies/labelCost/matlab'];
paths.meanShiftPath = [parentDir, 'dependencies/meanShift/bagon'];
paths.robustPnPath = [parentDir, 'dependencies/robustpn'];

%% Mat functions
paths.matCode = [parentDir,   'matlabcodes'];
paths.functions = [parentDir, 'matlabcodes/functions'];
paths.stereoExp = [parentDir, 'matlabcodes/stereo_experiments'];
paths.inpaintExp = [parentDir,'matlabcodes/inpainting_experiments'];

%% adding paths
addpath(genpath(pwd), paths.parentDir, paths.coocPath);
addpath(paths.hierPnPath, paths.labelCostPath, paths.meanShiftPath, paths.robustPnPath);
addpath(paths.matCode, paths.stereoExp, paths.inpaintExp);
