#!/bin/sh

timeout=$1
if [ -z "${timeout##*[!0-9]*}" ];then
	timeout=5
fi

if $(dirname $0)/is_online.sh cloudy $timeout;then
	if rsync --password-file="$HOME/.ssh/backup.rsync" backup@cloudy::Backup/delly/ > /dev/null;then
		exit 0
	fi
fi

exit 1
