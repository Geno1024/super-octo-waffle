#!/bin/bash

# a temporary file store raw data
tempfile=/tmp/`date +%s`

# parse command line param
while getopts f:o:s:l:hv opts; do
    case $opts in
        f) func=$OPTARG ;;
        o) output=$OPTARG ;;
        s) start=$OPTARG ;;
        l) length=$OPTARG ;;
        h) cat << EOF
Usage: $0 -f func [-o output.txt] [-s start] [-l length] [-h] [-v]
Convert func to sample data, ready for parse by dec2wav.sh.

Sample:
s(x*1000/22050*3.1415926)
produce the 1k sine wave.
EOF
exit -1
;;
        v) cat << EOF
Author: Geno1024
Date: 2019-05-03
Version: 00.01.0074
EOF
exit -1
;;
        ?) ;;
    esac
done

# if no func then error
if [[ $func == "" ]]; then
    echo "Function must be specified." >&2
    exit -1
fi

# if have output then write stdout
if [[ $output != "" ]]; then
    exec 1>"$output"
fi

# if no start then start 0
if [[ $start == "" ]]; then
    start=0
fi

# if no length then length 1s
if [[ $length == "" ]]; then
    length=44100
fi

bc -l <<< "for (x = $start; x < ($start + $length); x++) { r = 32768 * ($func) * 0.7071067812; if (r < 0) r = 65536 + r; scale = 0; r / 1; scale = 20; }"
