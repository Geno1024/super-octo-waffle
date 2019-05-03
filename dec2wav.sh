#!/bin/bash

# a temporary file store raw data
tempfile=/tmp/`date +%s`

# parse command line param
while getopts i:o:r:h opts; do
    case $opts in
        i) input=$OPTARG ;;
        o) output=$OPTARG ;;
        r) rate=$OPTARG ;;
        h) cat << EOF
Usage: $0 [-i input.txt] [-o output.wav] [-r rate] [-h] [-v]
Convert numeric analog data to wav file.

EOF
exit -1
;;
        v) cat << EOF
Author: Geno1024
Date: 2019-05-02
Version: 00.01.0084
EOF
;;
        ?) ;;
    esac
done

# if no input then read stdin
if [[ $input == "" ]]; then
    tempin=/tmp/in`date +%s`
    while read line
    do
        echo "$line" >> "$tempin"
    done
    input="$tempin"
fi

# if have output then write stdout
if [[ $output != "" ]]; then
    exec 1>"$output"
fi

# if no rate then rate 44100
if [[ $rate == "" ]]; then
    rate=44100
fi

channels=$(head -n 1 "$input" | awk '{print NF}')

# convenient function
byte4tobe() {
    printf "%08x" $1 | awk '{printf("%s%s%s%s", substr($1, 7, 2), substr($1, 5, 2), substr($1, 3, 2), substr($1, 1, 2))}' | xxd -r -p
}

byte2tobe() {
    printf "%04x" $1 | awk '{printf("%s%s", substr($1, 3, 2), substr($1, 1, 2))}' | xxd -r -p
}

# Part 1: Convert data
cat "$input" | xargs printf "%04x\n" | awk '{printf("%s%s\n", substr($1, 3, 2), substr($1, 1, 2))}' | xxd -r -p > "$tempfile"

# Phase 2: write music header

## 52 49 46 46
echo -n "RIFF"
## 24 08 00 00 file size
byte4tobe $(($(wc -c "$tempfile" | awk '{print $1}') + 44))
## 57 41 56 45 
echo -n "WAVE"

## 66 6d 74 20
echo -n "fmt "
## 10 00 00 00 subchunk size, hardcode
echo -ne "\x10\0\0\0"
## 01 00 audio format = PCM, hardcode
echo -ne "\x01\0"
## 01 00 number of channels
byte2tobe $channels
## 44 ac 00 00 sample rate
byte4tobe $rate
## 10 b1 02 00 byte rate
byte4tobe $(($rate * $channels * 2))
## 04 00 block align
byte2tobe $(($channels * 2))
## 10 00 bits per sample, hardcode
echo -ne "\x10\0"

## 64 61 74 61
echo -n "data"
byte4tobe $(wc -c "$tempfile" | awk '{print $1}')
cat "$tempfile"

rm "$tempfile"
