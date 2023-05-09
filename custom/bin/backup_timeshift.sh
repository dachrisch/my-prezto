#!/bin/bash

# https://unix.stackexchange.com/questions/239772/bash-iterate-file-list-except-when-empty
shopt -s nullglob

# exit on error
set -e

source_dir=/timeshift/snapshots

log() {
	echo "[$(date +"%d-%m-%Y %H:%M")] - $*"
}

logn() {
	echo -n "[$(date +"%d-%m-%Y %H:%M")] - $*"
}

if [ "$1" = "-l" ];then

	backup_dir=/timeshift/snapshots-backups
	filter_snapshots=/timeshift/snapshots-hourly
	if [ ! -d "$backup_dir" ];then
		sudo mkdir "$backup_dir"
	fi

	log "removing old backups in [$backup_dir]"
	for snapshot in "$backup_dir"/*.tgz;do
		expected_snapshot_dir=$source_dir/$(basename "${snapshot::-4}")
		logn "considering [$(basename "$snapshot")] of [$expected_snapshot_dir]..."
		if [ -d "$expected_snapshot_dir" ];then
			echo "keep."
		else
			echo "deleting."
			sudo rm "$snapshot"
		fi
	done


	log "creating local backups of snapshot in [$backup_dir]"
	for snapshot in "$source_dir"/*;do
		snapshot_name=$(basename "$snapshot")
		backup_file="$backup_dir/$snapshot_name.tgz"
		logn "archiving [$backup_file]..."

		if [ -d "$filter_snapshots/$snapshot_name" ];then 
			echo "skipped. (filtered)"
		elif [ -f "$backup_file" ];then
			echo "skipped. (existing)"
		else
			sudo tar --use-compress-program=pigz -c -P -f "$backup_file" "$snapshot" 
			echo "done."
		fi
	done
	log "local backup created...done."

	BACKUP_BASE=/home/daehnc/Downloads/local_backups
	BACKUP_NAME=timeshift
	latest_backup_file=$(ls -td -- "$backup_dir"/*|head -1)
	latest_backup_file_basename=$(basename $latest_backup_file)
	ENCRYPT_DIR="$BACKUP_BASE/encrpyted_backups"
	log "creating encrypted version of [$latest_backup_file] in [$ENCRYPT_DIR]"
	pushd $ENCRYPT_DIR > /dev/null
	sudo -u daehnc $(which encrypt_ssh.sh) $latest_backup_file
	mv "${latest_backup_file_basename}.enc" "${BACKUP_NAME}_${latest_backup_file_basename}.enc"
	mv "${latest_backup_file_basename}.key.enc" "${BACKUP_NAME}_${latest_backup_file_basename}.key.enc"
	ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2 | xargs rm --
	ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.key.enc |tail -n +2 | xargs rm --

else
	latest_snapshot=$(ls -td -- "$source_dir"/*|head -1)/
	echo '{"timestamp":'$(date +%s)', "dateString": "'$(date +%FT%T.%3N)'"}' | jq . | sudo tee "$latest_snapshot.last_backup"

	remote_backup_location=backup@cloudy::Backup/$(hostname)/timeshift/
	log "syncing [$latest_snapshot] with [$remote_backup_location]..."
	set -e
	sudo rsync --timeout=30 --stats -i -r -t -p -l -D --update --delete-after --password-file=/root/.ssh/backup.rsync --exclude "*.swap" "$latest_snapshot" "$remote_backup_location"
	set +e
	log "synced with remote location...done."
fi
# check md5sums
# ssh root@cloudy "find /volume1/Backup/delly/timeshift -type f -exec md5sum {} \;" | sed "s/\/volume1\/Backup\/delly\/timeshift\///" | md5sum --check