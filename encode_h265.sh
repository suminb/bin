#!/bin/sh

encode() {
    source="$1"
    basename=$(basename "${source%.*}")
    dirname=$(dirname "$source")
    target="${dirname}/${basename}_H265.mp4"
    # https://trac.ffmpeg.org/wiki/Encode/H.265
    # NOTE: -tag:v hvc1 makes possible to import the file into Final Cut Pro

    if [[ "$source" = *_H265.mp4 || "$source" = *_Original.mp4 ]]; then
        echo "${source} is already processed. Aborted."
        exit 1
    fi

    ffmpeg \
        -i "$source" \
        -c:v hevc_videotoolbox \
        -q:v 55 \
        -preset fast \
        -c:a aac \
        -b:a 128k \
        -g 60 \
        -x265-params "keyint=60:min-keyint=60" \
        -map_metadata 0 \
        -movflags frag_keyframe+empty_moov \
        -tag:v hvc1 \
        -y \
        "$target" && \
    touch -m -r "$source" "$target"


    # -vf scale=-1:720 \
    # -c:v libx265 \
    # -crf 23 \
}

encode "$1"
