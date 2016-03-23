#!/bin/bash
#$-cwd


#module load matlab
cd /home/users/pukumar/codes/hierPn/codes_new/allCodes
PROCSTRING="cd /home/users/pukumar/codes/hierPn/codes_new/allCodes; addpath(genpath(pwd)); stereoExperimentsFunction('$1',$2,$3,$4,$5,$6);"
echo $PROCSTRING
matlab -nodesktop -nosplash -nojvm -r "${PROCSTRING};exit(1);"


