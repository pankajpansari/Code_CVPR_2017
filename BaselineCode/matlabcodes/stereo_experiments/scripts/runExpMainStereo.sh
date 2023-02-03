#!/bin/bash
#$-cwd

#if [ ! -n "$1" ]
#    then
#    echo "Usage: " $0 " OBJ_CLASS"
#    exit
#else
#    ACTION=$1
#fi

stereoPairName=("teddy");
lambda=( 10 15 20 )
sigma=( 100 1000 10000 100000  )
truncation=( 1 5  )
mra=( 120 150 180 300 )
#mra=( 5 10 20 40 60 80 100 )
#mra=( 5 10 20 40 60 )
numTrees=3;

#stereoPairName=("tsukuba");
##lambda=( 20 )
#lambda=( 30 )
#sigma=( 100 1000 10000 100000 )
#truncation=( 5 10  )
##mra=( 100 120 140 160 200 )
#mra=( 250 300 )
#numTrees=3;

#RESULTDIR=/home/users/pukumar/codes/hierPn/codes_new/allCodes/matlabcodes/stereo_experiments/results_tsukuba/
RESULTDIR=/home/users/pukumar/codes/hierPn/codes_new/allCodes/matlabcodes/stereo_experiments/results/
LOGDIR=./PBS_STEREO/

if [ ! -d ${LOGDIR} ]; then
    echo "Log Directory ${LOGDIR} not present, creating it"
    mkdir $LOGDIR
fi

#if [ ! -d ${RESULTDIR} ]; then
#    echo "Result Directory ${RESULTDIR} not present, creating it"
#    mkdir $RESULTDIR
#fi

#stereoPairs = {'cones'; 'teddy'; 'tsukuba'; 'venus'};

#stereoPairNum=1;
#lambda=(10 20 30 40 50 60 );
#sigma=( 0.001 0.01 0.1 1 10 100 1000) ;
#truncation=( 1000 1500 2000 2500 );
#
#stereoPairNum=2;
#lambda=( 5 10 15 );
#sigma=( 0.001 0.01 0.1 1 10 100 1000 );
#truncation=( 1 4 8 );
#
#stereoPairNum=4
#lambda=( 30 40 50 );
#sigma=( 0.1 1 10 100 1000 );
#truncation=( 5 10 15 20 25 );
#
#stereoPairNum=4
#lambda=( 40 50 55 60 65 70 );
#sigma=( 0.001 0.01 0.1 1 10 100 1000 );
#truncation=( 40 50 60 );

#stereoPairName=("tsukuba");
#lambda=( 10 20 30 )
#sigma=( 0.01 0.1 10 100 1000 10000  )
#truncation=( 2 5 10 15  )
#mra=200

for l in ${lambda[@]};
do
    for s in ${sigma[@]};
    do
	for t in ${truncation[@]};
	do
	    for m in ${mra[@]};
	    do 
	    	JOB_NAME="${stereoPairName}_l${l}_s${s}_tr$t"
	    	LOGSTRING_ERR="${LOGDIR}${stereoPairName}_l${l}_s${s}_tr${t}_mra${m}.e"
	    	LOGSTRING="${LOGDIR}${stereoPairName}_l${l}_s${s}_tr${t}_mra${m}.o"
	    	qsub -N ${JOB_NAME} -o ${LOGSTRING} -e ${LOGSTRING_ERR} runExpHelperStereo.sh ${stereoPairName} ${l} ${s} ${t} ${numTrees} ${m} 
	    done
	done
    done
done
    
