#!/bin/bash
# Author: Morten Krogh Andersen / morten@krogh.net
# Date: 2020-05-23

function usage() {

	echo ""
	echo "This script sends cot events from a text file using either UDP or TCP"
	echo "Each message can span over multiple lines in the file, but each event end-tag must be a the end of a line"
	echo "socat must be installed for this script to work"
	echo "Author: Morten Krogh Andersen / morten@zimage.dk"
	echo ""
	echo "Usage: $(basename $0) options file"
	echo ""
	echo "Options:"
	echo "    -P --protocol [value]   transport protocol. Valid values: ucp or tcp. Default: udp"
	echo "    -a --address            destination host/ip address"
	echo "                            multicast transmission is possible by specifying a multicast address and udp as protocol"
	echo "    -p --port [value]       destination port"
	echo "    -i --interval [value]   the interval between message transmissions"
	echo "                            default time unit is seconds, default value is 10. See 'sleep --help' for valid values"
	echo "    -r --repeat             if specified, the script will keep running, sending the messages until stopped"
	echo "    -h --help               show this help"
}

if [ -z $(which socat) ] ; then
	echo "socat not installed!"
	usage
	exit 2
fi

if [[ $# -eq 0 ]]; then
	usage
	exit 0
fi

# File is the last argument
for file in $@; do :; done

while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-P|--protocol)
		proto="$2"
		shift
		;;
		-a|--address)
		address="$2"
		shift
		;;
		-p|--port)
		port="$2"
		shift
		;;
		-i|--interval)
		interval=$2
		shift
		;;
		-r|--repeat)
		repeat=
		;;
		-h|--help)
		usage
		exit 0
		;;
	esac
	shift
done

if [ -z "${proto}" ]; then
	echo "No protocol specified, using default: udp"
	proto=udp
elif [ "tcp" != "${proto}" ] && [ "udp" != "${proto}" ] ; then
	echo "Invalid protocol : ${proto}"
	usage
	exit 1
fi

if [ -z "${address}" ]; then
	echo "No address specified"
	usage
	exit 1
fi

if [ -z "${port}" ]; then
	echo "No port specified"
	usage
	exit 1
fi

if [ -z "${interval}" ]; then
	echo "No interval specified, defaulting to 10 secs"
	interval=10
fi

if [ ! -f "${file}" ] ; then
	echo "File \"$file\" not found"
	exit 1
fi

function send_udp() {
	echo "$1" | socat -d UDP-DATAGRAM:${address}:${port} -
}

function send_tcp() {
	echo "$1" | socat -d TCP:${address}:${port} -
}

msg=""
while read -s line; do
	msg="${msg}${line}"
	if [[ "${line}" == *"</event>" ]] ; then
		messages+=( "${msg}" )
		msg=""
	fi
done < "${file}"

echo -n "Transmitting ${#messages[@]} events with interval: ${interval}"
[[ -v repeat ]] && echo ", repeating" || echo ""

while [ 1 ] ; do
	idx=0
	for event in "${messages[@]}"; do
		idx=$((idx + 1))
		case $proto in
			udp)
				send_udp "${event}"
			;;
			tcp)
				send_tcp "${event}"
			;;
		esac
		# Don't wait after the last tx, if not on repeat
	    if [[ -v repeat ]] || [[ idx -lt ${#messages[@]} ]]; then
			sleep $interval
			# Die if sleep fails - most likely due to an invalid formatted parameter
			[ "$?" != "0" ] && exit 9
		fi
	done
    [[ ! -v repeat ]] && break
done
