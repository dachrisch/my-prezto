#!/bin/bash

timeout=$1
if [ -z "${timeout##*[!0-9]*}" ];then
	timeout=5
fi

if is_cloudy_backup_online.sh $timeout;then
	echo "we are online...executing remote"
	$*
else
	echo "we are offline...executing local"
	$* -l
fi
