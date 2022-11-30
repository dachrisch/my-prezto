#!/bin/bash

export BT_STANNY=04:FE:A1:03:63:D4
export BT_MAUSI=f4:1b:a1:31:24:ab
export BT_TASTI=28:37:37:34:CD:94
export BT_LAUTI=00:09:A7:12:20:9C
export BT_BOSY=4C:87:5D:2B:86:4A

usage() {
	error=$1
	shift
	echo "[$error]. usage: turn <bluetooth:id> <direction:on|off>"
}

turn_bt_device() {
	device=$( echo $1 | tr '[:upper:]' '[:lower:]' )
	direction=$2

	if [ -z "$device" ];then
		usage "device:id missing"
	elif [[ ! "${device}" =~ ^([0-9a-f][0-9a-f]\:){5}[0-9a-f][0-9a-f]$ ]];then
		usage "device:id incorrect [$device]"
		unset device
	elif [ -z "$direction" ];then
		usage "missing direction"
	elif [ ! "$direction" = "on" ] && [ ! "$direction" = "off" ];then
		usage "don't know direction [$direction]"
	else

		if [ "$direction" = "on" ] ;then
			command="connect"
		elif [ "$direction" = "off" ];then
			command="disconnect"
		else
			return 1
		fi

		bluetoothctl "$command" "$device"
	fi
}

