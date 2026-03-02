#!/bin/bash
CORES=$(nproc)
LOADAVG=$(awk '{ print $1 }' /proc/loadavg)
DROP_MULTIPLIER='-20'
PRIORITY_DROP=$(awk "BEGIN {print int($LOADAVG * $DROP_MULTIPLIER)}")
echo "$PRIORITY_DROP" > drop.txt
