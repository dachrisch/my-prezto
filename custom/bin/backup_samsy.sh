#!/bin/bash
set -e

phone_dir=$1
if [ ! -d "$phone_dir" ];then
	echo "phone dir [$phone_dir] does not exists..."
	printf 'is the phone mounted? (usually under \e]8;;file://%s\e\\%s)\e]8;;\e\\\n' "/run/user/1000/gvfs/" "/run/user/1000/gvfs/"
	exit 1
fi

backup_file=~/Downloads/local_backups/samsy_backup_"$(date +%F)".tgz
tmp_dir=~/Downloads/local_backups/samsy

rsync -h --progress --stats -r -tgo -p -l -D --update --delete-after --delete-excluded --ignore-errors --exclude=**/Telegram\ Video/ --exclude=**/Telegram\ Audio/ --exclude=**/*tmp*/ --exclude=**/*cache*/ --exclude=**/*Cache*/ --exclude=**~ --exclude=**/lost+found*/ --exclude=/sys/** --exclude=**/*Trash*/ --exclude=**/*trash*/ --exclude=**/.gvfs/  --exclude=*backup*/ --exclude=*.db-wal --exclude=**/DCIM  "$phone_dir" $tmp_dir
tar --use-compress-program=pigz -c -P -f "$backup_file" $tmp_dir

printf 'successfully created backup: \e]8;;file://%s\e\\%s\e]8;;\e\\\n' "$backup_file" "$backup_file"

backup_samsy_pictures.sh "$phone_dir"
