#!/bin/bash

endpoint="http://hyperion.shortbread.io:8000"
source="$1"
basename=$(basename "${source%.*}")
dirname=$(dirname "$source")
target=${dirname}/${basename}_H265.mp4
# https://trac.ffmpeg.org/wiki/Encode/H.265
# NOTE: -tag:v hvc1 makes possible to import the file into Final Cut Pro

if [[ "$source" = *_H265.mp4 || "$source" = *_Original.mp4 ]]; then
    echo "${source} is already processed. Aborted."
    exit 1
fi

ffmpeg -i $(aws --endpoint-url=$endpoint s3 presign "$source") -c:v libx265 -crf 23 -preset fast -c:a aac -b:a 128k -map_metadata 0 -tag:v hvc1 -y -f mp4 -movflags frag_keyframe+empty_moov pipe:1 | aws --endpoint-url=$endpoint s3 cp - "$target" && \
    aws --endpoint-url=$endpoint s3 rm "$source"
