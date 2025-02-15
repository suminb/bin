#!/bin/bash

year=2024
path1="/Volumes/T7/White Rabbit $year.fcpbundle"
# tar -C /Volumes/T7 --zstd -cv "$path1" | gsplit -d -b 4G -a 4 - part_ --filter='aws --endpoint-url=http://hyperion.shortbread.io:8000 s3 cp - s3://archive/white-rabbit-t7/$FILE'
tar -C /Volumes/T7 --zstd -cv "$path1" | gsplit -d -b 4G -a 4 - part_ --filter='aws --endpoint-url=https://kr.object.ncloudstorage.com --profile=ncloud s3 cp - s3://archive.shortbread.io/backup/white-rabbit-$year/$FILE'

#path2="/Volumes/Backup2/White Rabbit (archived).fcpbundle"
#tar -cvf - "$path2" | gsplit -d -b 4G -a 4 - part_ --filter='aws --endpoint-url=http://hyperion.shortbread.io:8000 s3 cp - s3://archive/white-rabbit-archived/$FILE'
