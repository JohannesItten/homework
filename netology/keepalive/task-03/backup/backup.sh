#!/bin/bash
# better approach is to multiply by 100 and set weight=1
LOADAVG=$(awk '{ print int($1) }' /proc/loadavg)
echo $LOADAVG > /etc/keepalived/loadavg.txt
