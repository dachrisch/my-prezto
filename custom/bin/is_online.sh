#!/bin/sh

host=$1
timeout=$2

if [ -z "$host" ];then
	host=google.com
fi
if [ -z "${timeout##*[!0-9]*}" ];then
	timeout=5
fi

for i in $(seq 1 $timeout);do
	if ping -c1 $host > /dev/null 2>&1;then
		# echo "we are online"
		exit 0
	else
		seconds_to_wait=$((i * 10))
		echo "we are offline...waiting ${seconds_to_wait}s"
		sleep $seconds_to_wait
	fi
done
exit 1
