#!/bin/sh

source=$1
base=$(basename "${source%.*}")
target=${base}_H264.mp4
ffmpeg \
    -i $source \
    -c:v libx264 \
    -crf 23 \
    -preset fast \
    -c:a aac \
    -b:a 128k \
    -map_metadata 0 \
    -tag:v hvc1 \
    $target
touch -m -r $source $target
