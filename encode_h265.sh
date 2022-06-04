#!/bin/sh

source=$1
basename=$(basename "${source%.*}")
dirname=$(dirname "$source")
target=${dirname}/${basename}_H265.mp4
# https://trac.ffmpeg.org/wiki/Encode/H.265
# NOTE: -tag:v hvc1 makes possible to import the file into Final Cut Pro

if [[ "$source" = *_H265.mp4 || "$source" = *_Original.mp4 ]]; then
    echo "${source} is already processed. Aborted."
    exit 1
fi

ffmpeg \
    -i "$source" \
    -c:v libx265 \
    -crf 23 \
    -preset fast \
    -c:a aac \
    -b:a 128k \
    -map_metadata 0 \
    -tag:v hvc1 \
    -y \
    "$target" && \
touch -m -r "$source" "$target"
