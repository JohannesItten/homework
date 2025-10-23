#!/bin/bash

declare PROC_LIST
LOG_FILE='proclog.log'
LAST_CHECK_FILE='lasctheckdate.log'
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
MAX_VAL_LEN=15
declare -A LOG_HEADER_DICT=( 
				[cmdline]='CMD'
				[environ]='ENV'
				[limits]='LIM'
				[mounts]='MNT'
				[status]='STATUS'
				[cwd]='CWD'
				[fd]='FD'
				[fdinfo]='FDI'
				[root]='ROOT'
			)
AVAIL_OPTIONS=('cmdline' 'environ' 'limits' 'mounts' 'status' 'cwd' 'fd' 'fdinfo' 'root')
declare -a USER_OPTIONS

process_options() {
	USER_OPTIONS=(${AVAIL_OPTIONS[@]})
}

check_root() {
	local user_id
	user_id=$(id -u "$USER")
	if [[ ! $user_id -eq 0 ]]; then
		echo 'You must be root to run this script'
		exit 1
	fi
}

get_proc_list() {
	local last_check_date
	last_check_date='1970-01-01 00:00:00'
	if [[ -s "$LAST_CHECK_FILE" ]]; then
		last_check_date=$(<"$LAST_CHECK_FILE")
	fi
	# find dir's modified later, than $last_check_date
	# of course, better to calc timestamp based on jiffies,
	# but it's just a homework
	local find_cmd
	find_cmd="find /proc -maxdepth 1 \
			-type d \
			-regex '^/proc/[0-9]+$' \
			-newermt '$last_check_date'"
	IFS=" "
	mapfile -t PROC_LIST < <(eval "$find_cmd")
	unset IFS
}

get_name() {
	local pid=$1
	name=$(readlink "$pid")
	if [[ $name == "" && -f "$pid/comm" ]]; then
		name=$(<"$p/comm")
	fi
}

get_status() {
	if [[ ! "${USER_OPTIONS[*]}" =~ 'status' ]]; then
		return 1
	fi
	# current process state: R/D/S/T/Z
	local pid=$1
	# set U as Unknown
	status="U"
	if [[ -f "$pid/status" ]]; then
		status=$(grep 'State' "$pid/status" | awk '{ print $2 }')
	fi
}

create_log_header() {
	local log_header
	log_header+=$(printf '%-7s %-15s' 'PID' 'NAME')
	echo $USER_OPTIONS
	for opt in "${USER_OPTIONS[@]}"; do
		log_header+=$(printf "%-${MAX_VAL_LEN}s" "${LOG_HEADER_DICT[$opt]}")
	done
	echo "$log_header" > $LOG_FILE
}

process_proc_list() {
	printf '=%.0s' {1..30}; echo	
	echo "$CURRENT_DATE"
	printf '=%.0s' {1..30}; echo	
	for p in "${PROC_LIST[@]}"; do
		local pid
		pid=$(basename "$p")
		# get proc name
		local name
		get_name "$p"
		# get status
		local status
		get_status "$p"
		echo "$pid $name $status"
	done
}

check_root
process_options "$@"
get_proc_list
create_log_header
process_proc_list
