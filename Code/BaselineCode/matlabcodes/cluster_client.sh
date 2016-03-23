#!/bin/sh
python job_generator_matlab.py
cp command_list.txt jobsQueued.txt
perl clusterClient.pl -d /home/pankaj/Max_of_convex_code_new/Code/Baseline_code/matlabcodes
