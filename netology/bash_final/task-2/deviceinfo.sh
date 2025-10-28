#!/bin/bash

DEVICE_FILE='/proc/bus/input/devices'

task_21() {
	echo "Task 2.1. List files in /proc/bus/input"
	for file in /proc/bus/input/*; do
		basename "$file"
	done
}

create_out_str() {
	local -r header="$1"
	local -r line="$2"
	local str=$(echo "$line" | cut -d'=' -f2)
	printf "%-18s %s\n" "$header:" "$str"
}

task_22() {
	while IFS= read -r line; do
		case "$line" in
			I:*)
				printf "%-18s %s\n" "ID:" "${line#I: }"
				;;	
			N:*)
				create_out_str 'Name' "${line#N: }" 
				;;
			P:*)	
				create_out_str 'Physical location' "${line#P: }" 
				;;
			S:*)
				create_out_str 'Sysfs path' "${line#S: }" 
				;;
			U:*) 
				create_out_str 'Unique ID' "${line#U: }" 
				;;
			H:*) 
				create_out_str 'Handlers' "${line#H: }" 
				;;
			B:*)
				printf "%-18s %s\n" "Capabilities:" "${line#B: }"
				;;	
		esac
		if [[ -z $line ]]; then
			printf '%*s\n' 50 | tr ' ' '='	
		fi
	done < "$DEVICE_FILE" 
	#done < "$HOME/devices"
}

LOG_FILE="$HOME/devicelog.log"
task_23() {
	local date
	date=$(date '+%d.%m.%Y %H:%M:%S')
	local tmp_new='/tmp/devices.new'
	local tmp_old='/tmp/devices.old'
	# if LOG_FILE already exist, get previously known devices
	# if not, just write all found input devices to LOG_FILE
	# and exit from function
	local new
	new=$(grep -e '^I' "$DEVICE_FILE" | sort | uniq 2> /dev/null)
	if [[ -e "$LOG_FILE" ]]; then
		grep -e '^I' "$LOG_FILE" | sort | uniq 1> "$tmp_old"
		echo "$new" > "$tmp_new"
	else
		echo "$new" > $LOG_FILE
		echo "$date" >> $LOG_FILE
		return 0
	fi
	# get difference between new and known devices
	# if difference found, update log
	local diff
	diff=$(comm -23 "$tmp_new" "$tmp_old")
	local is_new_found=0
	for d in "$diff"; do
		if [[ $d == "" ]]; then
			continue
		fi
		echo "$d" >> "$LOG_FILE"
		is_new_found=1
	done
	if [[ $is_new_found -eq 1 ]]; then
		echo "$date" >> $LOG_FILE
	fi
	rm -f '/tmp/devices.old'
	rm -f '/tmp/devices.new'	
}

if [[ "$1" == "-v" ]]; then
	task_22
	exit 0
fi
task_23
