#!/bin/bash
ITER_NUM=0
DIST=1
TRUNC=10
INTERVAL_LEN=5
WEIGHT=5
m=1
for ITER_NUM in {0..5} ; do
	for TRUNC in {5..15..5} ; do
		~/Max_of_convex_code_new/Code/p_generate_input_file $ITER_NUM $DIST $TRUNC $INTERVAL_LEN $WEIGHT $m
		OUTPUT_FILE="../../output_logs/cooc_logs/linear_M${TRUNC}_w${WEIGHT}_iter${ITER_NUM}.txt"
		echo "$OUTPUT_FILE"
		matlab -nosplash -nodisplay -nojvm -r "wrapperParsimoniousCOOC('../../input_instance.txt'),quit()" > $OUTPUT_FILE 
	done
done
