#!/bin/bash
#$-cwd

#if [ ! -n "$1" ]
#    then
#    echo "Usage: " $0 " OBJ_CLASS"
#    exit
#else
#    ACTION=$1
#fi

LOGDIR=./PBS_PENGUIN/

if [ ! -d ${LOGDIR} ]; then
    echo "Log Directory ${LOGDIR} not present, creating it"
    mkdir $LOGDIR
fi

#if [ ! -d ${RESULTDIR} ]; then
#    echo "Result Directory ${RESULTDIR} not present, creating it"
#    mkdir $RESULTDIR
#fi

imName=("penguin");
lambda=( 30 40 50 );
sigma=( 100 1000 10000 ) ;
truncation=( 40 50  );
mra=( 200 300 );


#imName=("house");
#lambda=( 30 40 50 );
#sigma=( 100 1000 10000 ) ;
#truncation=( 40 50  );
#mra=( 200 300 );
#

for l in ${lambda[@]};
do
    for s in ${sigma[@]};
    do
	for t in ${truncation[@]};
	do
	    for m in ${mra[@]};
	    do
	    	JOB_NAME="in${stereoPairNum}_l${l}_s${s}_tr${t}"
	    	LOGSTRING_ERR="${LOGDIR}s${stereoPairNum}_l${l}_s${s}_tr${t}_mra${m}.e"
	    	LOGSTRING="${LOGDIR}s${stereoPairNum}_l${l}_s${s}_tr${t}_mra${m}.o"
	    	qsub -N ${JOB_NAME} -o ${LOGSTRING} -e ${LOGSTRING_ERR} runHelperInpaint.sh ${imName} ${l} ${s} ${t} ${m} 
	    done
	done
    done
done
    
