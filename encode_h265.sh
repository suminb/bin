#!/bin/sh

file=$1
base=$(basename "${file%.*}")
# NOTE: -tag:v hvc1 makes possible to import the file into Final Cut Pro
ffmpeg \
    -i $file \
    -c:v libx265 \
    -crf 23 \
    -preset fast \
    -c:a aac \
    -b:a 128k \
    -map_metadata 0 \
    -tag:v hvc1 \
    ${base}_H265.mp4
