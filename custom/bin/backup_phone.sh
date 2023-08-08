#!/bin/bash
set -e

phone_dir=$1
type=$2
if [ ! -d "$phone_dir" ];then
	echo "phone dir [$phone_dir] does not exists..."
	printf 'is the phone mounted? (usually under \e]8;;file://%s\e\\%s)\e]8;;\e\\\n' "/run/user/1000/gvfs/" "/run/user/1000/gvfs/"
	exit 1
fi

if [ -z "$type" ];then
	echo "type not specified"
	exit 2
fi

backup_file=~/Downloads/local_backups/${type}_backup_"$(date +%F)".tgz
tmp_dir=~/Downloads/local_backups/$type
filter_file="$(dirname $(dirname $0))/phone.filter"

rsync -h --progress --stats -r -tgo -p -l -D --update --delete-after --delete-excluded --ignore-errors --filter="merge $filter_file" "$phone_dir" $tmp_dir
tar --use-compress-program=pigz -c -P -f "$backup_file" $tmp_dir

printf 'successfully created backup: \e]8;;file://%s\e\\%s\e]8;;\e\\\n' "$backup_file" "$backup_file"

backup_phone_pictures.sh "$phone_dir"
