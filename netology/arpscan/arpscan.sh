#!/usr/bin/env bash

IP="$1"
INTERFACE="$2"

declare PREFIX
declare SUBNET
declare HOST

print_help() {
	echo 'Usage: arpscan.sh [IP] [INTERFACE]'
	echo 'Where IP=PREFIX.SUBNET.HOST:'
	echo '  [PREFIX]            first 2 octets, required'
	echo '  SUBNET              3rd octet'
	echo '  HOST                4th octet'
	echo 'Example: ./arpscan.sh 10.5 eth0'
}

handle_error() {
	echo -e "$1\n"
	print_help
	exit 1
}

handle_signal() {
	echo -e "\nRecieved signal $1. Shutting down..."
	exit 1
}

check_args() {
	if [[ -z "$IP" || -z "$INTERFACE"  || ! -z $3 ]]; then
		handle_error 'Incorrect args'
	fi
	
	local declare octets
	IFS='.' read -ra  octets <<< "$IP"
	local err_desc=('PREFIX' 'PREFIX' 'SUBNET' 'HOST')
	# check octet in range 0-255
	local regex='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$'
	local octets_amount=${#octets[@]}
	if [[ $octets_amount < 2 ]]; then
		handle_error 'Incorrect PREFIX'
	fi	
	for (( i=0; i<$octets_amount; i++ )); do
		local oct=${octets[i]}
		if [[ ! -z $oct && ! $oct =~ $regex ]]; then
			handle_error "Incorret ${err_desc[i]}"
		fi
	done
	PREFIX="${octets[0]}.${octets[1]}"
	SUBNET="${octets[2]}"
	HOST="${octets[3]}"
}

check_root() {
	readonly id=$(id -u $USER)
	if [[ $id -ne 0 ]]; then
		echo "The script must be run as root."
		exit 1
	fi
}

arp_scan_host() {
	local subnet=$1
	local host=$2
	echo "[*] IP : ${PREFIX}.${subnet}.${host}"
	arping -c 3 -i "$INTERFACE" "${PREFIX}.${subnet}.${host}" 2> /dev/null
}

arp_scan() {
	declare local subnet_start subnet_fin host_start host_fin
	if [[ -z $SUBNET ]]; then
		subnet_start=0
		subnet_fin=255
	else
		subnet_start=$SUBNET
		subnet_fin=$SUBNET
	fi
	if [[ -z $HOST ]]; then
		host_start=0
		host_fin=255
	else
		host_start=$HOST
		host_fin=$HOST
	fi

	for subnet in $(seq $subnet_start $subnet_fin)
	do
		for host in $(seq $host_start $host_fin)
		do
			arp_scan_host $subnet $host 
		done
	done
}

# traps for signal handling must be the first task point,
# otherwise it's painful to work with script
trap 'handle_signal SIGINT' SIGINT
trap 'handle_signal SIGTERM' SIGTERM

check_args $@
check_root
arp_scan
