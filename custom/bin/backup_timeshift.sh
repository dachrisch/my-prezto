#!/bin/zsh

# https://unix.stackexchange.com/questions/239772/bash-iterate-file-list-except-when-empty
shopt -s nullglob

# exit on error
set -e
source "$HOME/.zprezto/custom/functions/logdy"

source_dir=/timeshift/snapshots
current_dir=$(dirname $0)

if [ "$1" = "-l" ];then

	backup_dir=/timeshift/snapshots-backups
	filter_snapshots=/timeshift/snapshots-hourly
	if [ ! -d "$backup_dir" ];then
		sudo mkdir "$backup_dir"
	fi

	logdy info "Removing old backups" backup_dir="$backup_dir"
	for snapshot in "$backup_dir"/*.tgz;do
		expected_snapshot_dir=$source_dir/$(basename "${snapshot::-4}")
		snapshot_name=$(basename "$snapshot")
		if [ -d "$expected_snapshot_dir" ];then
			logdy debug "Considering snapshot - keeping" snapshot="$snapshot_name" expected_dir="$expected_snapshot_dir"
		else
			logdy debug "Considering snapshot - deleting" snapshot="$snapshot_name" expected_dir="$expected_snapshot_dir"
			sudo rm "$snapshot"
		fi
	done


	logdy info "Creating local backups of snapshots" backup_dir="$backup_dir"
	for snapshot in "$source_dir"/*;do
		snapshot_name=$(basename "$snapshot")
		backup_file="$backup_dir/$snapshot_name.tgz"

		if [ -d "$filter_snapshots/$snapshot_name" ];then
			logdy debug "Archiving snapshot - skipped (filtered)" backup_file="$backup_file"
		elif [ -f "$backup_file" ];then
			logdy debug "Archiving snapshot - skipped (existing)" backup_file="$backup_file"
		else
			logdy debug "Archiving snapshot" backup_file="$backup_file"
			sudo tar --use-compress-program=pigz -c -P -f "$backup_file" "$snapshot"
		fi
	done
	logdy info "Local backup created"

	BACKUP_BASE=/home/daehnc/Downloads/local_backups
	BACKUP_NAME=timeshift
	latest_backup_file=$(ls -td -- "$backup_dir"/*|head -1)
	latest_backup_file_basename=$(basename $latest_backup_file)
	ENCRYPT_DIR="$BACKUP_BASE/encrpyted_backups"
	logdy info "Creating encrypted version" source_file="$latest_backup_file" encrypt_dir="$ENCRYPT_DIR"
	pushd $ENCRYPT_DIR > /dev/null
	sudo -u daehnc "$current_dir/encrypt_ssh.sh" $latest_backup_file
	mv "${latest_backup_file_basename}.enc" "${BACKUP_NAME}_${latest_backup_file_basename}.enc"
	mv "${latest_backup_file_basename}.key.enc" "${BACKUP_NAME}_${latest_backup_file_basename}.key.enc"
	if [ ! -z "$(ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2)" ];then
		ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2 | xargs rm --
		ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.key.enc |tail -n +2 | xargs rm --
	fi
else
	latest_snapshot=$(ls -td -- "$source_dir"/*|head -1)/
	echo '{"timestamp":'$(date +%s)', "dateString": "'$(date +%FT%T.%3N)'"}' | jq . | sudo tee "$latest_snapshot.last_backup"

	remote_backup_location=backup@cloudy::Backup/$(hostname)/timeshift/
	logdy info "Syncing with remote location" source="$latest_snapshot" destination="$remote_backup_location"
	set -e
	sudo rsync --timeout=30 --stats -i -r -t -p -l -D --update --delete-after --password-file=/root/.ssh/backup.rsync --exclude "*.swap" "$latest_snapshot" "$remote_backup_location"
	set +e
	logdy info "Synced with remote location"
fi
# check md5sums
# ssh root@cloudy "find /volume1/Backup/delly/timeshift -type f -exec md5sum {} \;" | sed "s/\/volume1\/Backup\/delly\/timeshift\///" | md5sum --check
