#!/bin/bash

declare MODE
# list of directories like /proc/[1-9]
declare PROC_LIST
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
AVAIL_OPTIONS=('cmdline' 'environ' 'limits' 'mounts' 'status' 'cwd' 'fd' 'fdinfo' 'root')
declare -a USER_OPTIONS

LOG_FILE='/var/log/proclog.log'
# amount of spaces between log values
SPACES_LEN=3
# dictionary with log column names
declare -A LOG_HEADER_DICT=(
				[pid]='PID'
				[name]='NAME' 
				[cmdline]='CMD'
				[environ]='ENV'
				[limits]='LIMITS'
				[mounts]='MOUNTS'
				[status]='STATUS'
				[cwd]='CWD'
				[fd]='FD'
				[fdinfo]='FDINFO'
				[root]='ROOT'
			)
# dictionary with log values len
# each value will be truncated to this len
declare -A LOG_VALUE_LEN=( 
				[pid]=10
				[name]=25
				[cmdline]=25
				[environ]=25
				[limits]=25
				[mounts]=15
				[status]=15
				[cwd]=25
				[fd]=15
				[fdinfo]=15
				[root]=25
			)

print_help() {
	echo -e "Usage: procmon.sh [argument] {options}\n"
	echo "Arguments:"
	echo "  -s [options]        silent mode"
	echo "  -i [options]        interactive mode"
	echo "  -h, --help          display this help and exit"
	echo "Options (at least 4 required):"
	echo "  cmdline             command line used to start process"
	echo "  environ             value of HOME env varible"
	echo "  limits              max open files limit"
	echo "  mounts              amount of tmpfs in process namespace"
	echo "  status              current state"
	echo "  cwd                 process cwd"
	echo "  fd                  amount of links to socket in /proc/pid/fd"
	echo "  fdinfo              mount point of proc stdout"
	echo "  root                process root"
	echo "Example: ./procmon.sh -s cmdline environ limits status"
}

process_user_options() {
	local args=("$@")
	for ((i=1; i<"$#"; ++i)); do
		local option
		option="${args[$i]}"
		if [[ ! "${AVAIL_OPTIONS[*]}" =~ $option ]]; then
			echo -e "Unknown options: $option\n"
			print_help
			exit 1
		fi
		USER_OPTIONS+=("$option")
	done
	if [[ "${#USER_OPTIONS[@]}" -lt 4 ]]; then
		echo -e "Insufficient amount of options. Need at least 4\n"
		print_help
		exit 1
	fi
	USER_OPTIONS=('pid' 'name' "${USER_OPTIONS[@]}")
}

process_args() {
	case "$1" in
		-h|--help)
			print_help
			exit 0 ;;
		-i)
			MODE='interactive'
			process_user_options "$@"
			echo 'Interactive mode'
			echo "Selected options: ${USER_OPTIONS[*]}" ;;
		-s)
			MODE='silent'
			process_user_options "$@" ;;
		*)
			echo -e 'Unknown argument\n'
			print_help
			exit 1 ;;
	esac
}

check_user_root() {
	local user_id
	user_id=$(id -u "$USER")
	if [[ ! $user_id -eq 0 ]]; then
		echo 'You must be root to run the script'
		exit 1
	fi
}

check_log_permissions() {
	if [[ ! -e "$LOG_FILE" ]]; then
		touch "$LOG_FILE" 2> /dev/null
		if ! touch "$LOG_FILE" 2> /dev/null; then
			echo "Can't create log file: $LOG_FILE"
			exit 1
		fi 
	fi
	if [[ ! -w "$LOG_FILE" || ! -r "$LOG_FILE" ]]; then
		echo "User must have read/write access to: $LOG_FILE"
		exit 1
	fi
}

get_proc_list() {
	local last_check_date
	last_check_date='1970-01-01 00:00:00'
	if [[ -s "$LOG_FILE" ]]; then
		local date date_regex
		date=$(tail -n 1 "$LOG_FILE")
		date_regex='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) '
		date_regex+='([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
		if [[ $date =~ $date_regex ]]; then
			last_check_date=$date
		fi
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

get_pid() {
	basename "$1"
}

get_name() {
	name=$(readlink "$1/exe")
	if [[ -z $name && -f "$1/comm" ]]; then
		name=$(<"$1/comm")
	fi
	# name can be still empty in cases like
	# status == D (uniterruptible sleep) or even S (sleep)
	echo "$name"
}

get_cmdline() {
	local fname="$1/cmdline"
	local cmdline=''
	if [[ -f "$fname" ]]; then
		cmdline=$(tr -d '\0' <"$fname")
	fi
	echo "$cmdline"
}

get_environ() {
	# gets value of HOME env variable
	local fname="$1/environ"
	local environ=''
	if [[ -f "$fname" ]]; then
		environ=$(tr '\0' '\n' < "$fname" | grep 'HOME')
	fi
	echo "$environ"
}

get_limits() {
	# gets value 'Max open files' from /proc
	local fname="$1/limits"
	local limits=''
	if [[ -f "$fname" ]]; then
		limits=$(grep 'Max open files' "$fname" \
			| awk '{ printf "%s/%s/%s", $4, $5, $6}')
	fi
	echo "$limits"
}

get_mounts() {
	# gets amount of tmpfs from /proc
	local fname="$1/mounts"
	local mounts='tmpfs:0'
	if [[ -f "$fname" ]]; then
		local amount
		amount=$(grep -c -e '^tmpfs' "/proc/$pid/mounts")
		mounts="tmpfs:$amount"
	fi
	echo "$mounts"
}

get_status() {
	# current process state: R/D/S/T/Z
	local fname="$1/status"
	local status=""
	if [[ -f "$fname" ]]; then
		status=$(grep 'State' "$fname" | awk '{ print $2, $3 }')
	fi
	echo "$status"
}

get_cwd() {
	local cwd
	cwd=$(readlink "$1/cwd")
	echo "$cwd"
}

get_fd () {
	# get amount of links to socket from /proc
	local fname="$1/fd"
	local fd='socket:0'
	if [[ -d "$fname" ]]; then
		local amount
		amount=$(find "$fname" -type l -ls | grep -c 'socket')
		fd="socket:$amount"
	fi
	echo "$fd"
}

get_fdinfo() {
	# get mount point of proc stdout
	local fname="$1/fdinfo/1"
	local fdinfo mount_id
	if [[ -f "$fname" ]]; then
		mount_id=$(grep 'mnt_id' "$fname" | awk '{ print $2 }')
	fi
	fname="$1/mountinfo"
	if [[ -n $mount_id && -f "$fname" ]]; then
		fdinfo=$(grep -e "^$mount_id" "$fname" | cut -d ' ' -f 5)
	fi
	echo "$fdinfo"
}

get_root() {
	local root
	root=$(readlink "$1/root")
	echo "$root"
}

create_log_header() {
	local log_header
	for opt in "${USER_OPTIONS[@]}"; do
		local val_len=${LOG_VALUE_LEN[$opt]}
		val_len=$((val_len + SPACES_LEN))
		log_header+=$(printf "%-${val_len}s" "${LOG_HEADER_DICT[$opt]}")
	done
	echo "$log_header" >> $LOG_FILE
}

process_proc_list() {
	local pid name
	for proc in "${PROC_LIST[@]}"; do
		local log_string
		log_string=''
		for opt in "${USER_OPTIONS[@]}"; do
			local func_name func_result
			func_name="get_$opt"
			func_result=$($func_name "$proc")
			local val_len col_len
			val_len="${LOG_VALUE_LEN[$opt]}"
			col_len=$((val_len + 3))
			log_string+=$(printf "%-${col_len}.${val_len}s" "$func_result")
		done
		if [[ $MODE == 'interactive' ]]; then
			echo -ne "Processed: $proc\r"
		fi
		echo "$log_string" >> "$LOG_FILE"
	done
	echo -e "$CURRENT_DATE" >> "$LOG_FILE"
}

process_args "$@"
check_user_root
check_log_permissions
get_proc_list
create_log_header
process_proc_list
if [[ $MODE == 'interactive' ]]; then
	while true; do
		echo -e '\nProcessing of /proc completed.'
		echo 'Run less to view log output? [y/n]'
		read -r choice
		if [[ $choice == 'y' || $choice == 'Y' ]]; then
			less -S "$LOG_FILE"
			exit 0
		elif [[ $choice == 'n' || $choice == 'N' ]]; then
			exit 0
		fi
	done
fi
