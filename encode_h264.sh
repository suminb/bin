#!/bin/sh

file=$1
base=$(basename "${file%.*}")
ffmpeg \
    -i $file \
    -c:v libx264 \
    -crf 23 \
    -preset fast \
    -c:a aac \
    -b:a 128k \
    -map_metadata 0 \
    -tag:v hvc1 \
    ${base}_H264.mp4