#!/bin/bash

# TODO: Perhaps we should take s3://backup/white-rabbit-t7 part as an argument as well
tar -cvf - "$1" | gsplit -d -b 4G -a 4 - part_ --filter='aws --endpoint-url=http://hyperion.shortbread.io:8000 s3 cp - s3://backup/white-rabbit-t7/$FILE'
