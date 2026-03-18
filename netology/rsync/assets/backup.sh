#!/bin/bash
SOURCE="/home/ubuntu/"
DEST="/tmp/backup"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
rsync -a --delete "${SOURCE}" "${DEST}" 2> /dev/null
RSYNC_STATUS=$?
if [ $RSYNC_STATUS -eq 0 ]; then
    logger -t 'backup-task-2' "[${DATE}] backup ${SOURCE} is ok"
else
    logger -t 'backup-task-2' "[${DATE}] backup ${SOURCE} failed"
fi
