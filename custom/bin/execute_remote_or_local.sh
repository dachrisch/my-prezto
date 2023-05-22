#!/bin/bash

timeout=$1
if [ -z "${timeout##*[!0-9]*}" ];then
	timeout=5
else
	shift
fi

basedir="$(dirname $0)"

if "$basedir/is_cloudy_backup_online.sh" $timeout;then
	echo "we are home...executing on cloudy"
	$*
elif "$basedir/is_online.sh" servyy.duckdns.org $timeout;then
	echo "we are remote...executing on servyy"
	$* -s
else
	echo "we are offline...executing local"
	$* -l
fi
