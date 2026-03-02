#!/bin/bash
LOADAVG=$(awk '{print $1 * 100}' /proc/loadavg)
# let's assume that 1.2 is critical loadavg for 2 cores
MAX_LOADAVG='120'
if [[ $LOADAVG -gt $MAX_LOADAVG ]]; then
        exit 1
fi
