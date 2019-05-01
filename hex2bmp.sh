#!/bin/bash

# a temporary file store raw data
tempfile=/tmp/`date +%s`

# parse command line param
while getopts :i:o:h opts; do
    case $opts in
        i) input=$OPTARG ;;
        o) output=$OPTARG ;;
        h) cat << EOF
Usage: $0 [-i input.raw] [-o output.bmp]
Convert line-space-matrix hex color representation to Windows BitMaP.

Sample Input:
FF0000 00FF00
0000FF FFFFFF
EOF
exit -1
;;
        v) cat << EOF
Author: Geno1024
Date: 2019-05-02
Version: 00.01.0055
EOF
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

# convenient function
byte4tobe() {
    printf "%08x" $1 | awk '{printf("%s%s%s%s", substr($1, 7, 2), substr($1, 5, 2), substr($1, 3, 2), substr($1, 1, 2))}' | xxd -r -p
}

# get image width and height
width=$(head -n 1 "$input" | awk '{print NF}')
height=$(wc -l "$input" | awk '{print $1}')

# Phase 1: write raw image
tac "$input" | awk '{ for (i = 1; i <= NF; i++) printf("%s%s%s ", substr($i, 5, 2), substr($i, 3, 2), substr($i, 1, 2)); print "0000"; }' | xxd -r -p > "$tempfile"

# get raw image size
bytes=$(wc -c "$tempfile" | awk '{print $1}')

# Phase 2: write image header

## 42 4d BMP header
echo -n "BM"
## 46 00 00 00 file size
byte4tobe $(($(wc -c "$tempfile" | awk '{print $1}') + 0x36))
## 00 00 reserved
echo -ne "\0\0"
## 00 00 reserved
echo -ne "\0\0"
## 36 00 00 00 offset of image data, hardcode
echo -ne "\x36\0\0\0"
## 28 00 00 00 DIB data size, hardcode
echo -ne "\x28\0\0\0"
## 02 00 00 00 width
byte4tobe $width
## 02 00 00 00 height
byte4tobe $height
## 01 00 number of planes, hardcode
echo -ne "\x01\0"
## 18 00 bits per pixel, hardcode
echo -ne "\x18\0"
## 00 00 00 00 compress, hardcode
echo -ne "\0\0\0\0"
## 10 00 00 00 image size
echo -ne "\x10\0\0\0"
## 23 2e 00 00 x resolution, hardcode?
echo -ne "\x23\x2e\0\0"
## 23 2e 00 00 y resolution, hardcode?
echo -ne "\x23\x2e\0\0"
## 00 00 00 00 number of colors, hardcode
echo -ne "\0\0\0\0"
## 00 00 00 00 number of important colors, hardcode
echo -ne "\0\0\0\0"

## append
cat "$tempfile"

# cleaning
rm "$tempfile" "$tempin"
