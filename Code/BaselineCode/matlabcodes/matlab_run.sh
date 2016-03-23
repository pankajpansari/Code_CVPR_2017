#!/bin/sh
matlab -nodisplay -nojvm -nosplash -r "wrapperParsimoniousCOOC('test1.txt'),quit()" > log.txt
