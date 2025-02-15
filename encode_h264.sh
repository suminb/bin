#!/bin/sh

encode() {
    source="$1"
    basename=$(basename "${source%.*}")
    dirname=$(dirname "$source")
    target="${dirname}/${basename}_H264.mp4"

    if [[ "$source" = *_H264.mp4 || "$source" = *_Original.mp4 ]]; then
        echo "${source} is already processed. Aborted."
        exit 1
    fi

    ffmpeg \
        -i "$source" \
        -c:v h264_videotoolbox \
        -q:v 55 \
        -preset fast \
        -c:a aac \
        -b:a 128k \
        -g 60 \
        -map_metadata 0 \
        -movflags frag_keyframe+empty_moov \
        -y \
        "$target" && \
    touch -m -r "$source" "$target"

    #-vf scale=-1:720 \
}

encode "$1"
