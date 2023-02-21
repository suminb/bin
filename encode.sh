#!/bin/bash

endpoint="http://hyperion.shortbread.io:8000"
subcommand="$1"

presign() {
    aws --endpoint-url=$endpoint s3 presign --expires-in 172800 "$1"
}

duration() {
    source="$1"
    ffprobe -show_entries format=duration -v quiet -of csv="p=0" "$source"
}

verify() {
    # Ensures that both videos have the same duration
    path1="$1"
    path2="$2"

    echo "Getting video duration for $path1"
    duration1=$(duration "$path1")
    echo "Getting video duration for $path2"
    duration2=$(duration "$path2")

    echo "$duration1, $duration2"
}

h265() {
    source="$1"
    target="$2"
    # https://trac.ffmpeg.org/wiki/Encode/H.265
    # NOTE: -tag:v hvc1 makes possible to import the file into Final Cut Pro

    ffmpeg \
        -i "$source" \
        -c:v libx265 \
        -crf 23 \
        -g 60 \
        -preset fast \
        -c:a aac \
        -b:a 128k \
        -map_metadata 0 \
        -movflags frag_keyframe+empty_moov \
        -tag:v hvc1 \
        -f mp4 \
        -y \
        "$target"
}

s3comp() {
    source="$1" # expects and S3 URL
    presigned_source=$(presign "$source")
    basename=$(basename "${source%.*}")
    dirname=$(dirname "$source")
    target="${dirname}/${basename}_H265.mp4"
    presigned_target=$(presign "$target")

    if [[ "$source" = *_H265.mp4 || "$source" = *_Original.mp4 ]]; then
        echo "${source} is already processed. Aborted."
        return false
    fi

    echo "Encode $source on S3, verify, and delete the original when completed"
    h265 "$presigned_source" "pipe:1" | aws --endpoint-url=$endpoint s3 cp - "$target"

    verify $presigned_source $presigned_target
}

case $subcommand in
    "presign")
        presign $2
        ;;
    "h265")
        echo "Not implemented"
        ;;
    "duration")
        duration ${@:2}
        ;;
    "verify")
        verify ${@:2}
        ;;
    "s3comp")
        s3comp "$2"
        ;;
    *)
        >&2 echo "Unknown command: ${subcommand}"
esac