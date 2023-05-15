#!/bin/bash

set -e 

if [ "$1" = "-l" ];then
	BACKUP_BASE=$HOME/Downloads/local_backups
	BACKUP_NAME=$(hostname)
	BACKUP_DIR="$BACKUP_BASE/$BACKUP_NAME"/
	if [ ! -d $BACKUP_DIR ];then mkdir -p $BACKUP_DIR;fi
	PASSWORD_OPTION=''
elif [ "$1" = "-s" ];then
	BACKUP_DIR=$HOME/Documents/storagebox/backup/$(hostname)/home/
	mkdir -p $BACKUP_DIR
	PASSWORD_OPTION=''
else
	BACKUP_DIR=backup@cloudy::Backup/$(hostname)/home/
	PASSWORD_OPTION="--password-file=$HOME/.ssh/backup.rsync"
fi

echo "backing up [$HOME]...to [$BACKUP_DIR]"

echo '{"timestamp":'$(date +%s)', "dateString": "'$(date +%FT%T.%3N)'"}' | jq . > "$HOME/.last_backup"

# https://serverfault.com/questions/279609/what-exactly-will-delete-excluded-do-for-rsync
rsync --timeout=30 --stats -i -r -tgo -p -l -D --update --no-links --no-specials --no-devices --delete-after --delete-excluded \
$PASSWORD_OPTION \
--exclude "**/google-chrome/" \
--exclude "/snap/" \
--exclude "/Insync/" \
--exclude "/Dropbox/" \
--exclude "/dev/**/*.vdi" \
--exclude "/Desktop/*.mov" \
--exclude "/Downloads/" \
--exclude "**/[Cc]ache/" \
--exclude "/.npm/" \
--exclude "**/.cache/" \
--exclude "/.dropbox*/" \
--exclude "/Documents/" \
--exclude "/Public/" \
--exclude "/Pictures/" \
--exclude "/Movies/" \
--exclude "/Music/" \
--exclude "/Library/*/*" \
--exclude "/Library/IdentityServices" \
--exclude "/Library/Messages" \
--exclude "/Library/HomeKit" \
--exclude "/Library/Sharing" \
--exclude "/Library/Mail" \
--exclude "/Library/Accounts" \
--exclude "/Library/Safari" \
--exclude "/Library/Suggestions" \
--exclude "/Library/PersonalizationPortrait" \
--exclude "/Library/Cookies" \
--exclude "/Library/Autosave Information" \
--exclude "**/.env/" \
--exclude "**/.venv/" \
--exclude ".DS_Store" \
--exclude ".localized" \
--exclude ".pyenv" \
--exclude ".zoom" \
--exclude ".java" \
--exclude ".Trash" \
--exclude "**/[tT]rash" \
--exclude ".git" \
--exclude "*/*.app/" \
--exclude ".zsh_sessions" \
--exclude "**/node_modules/" \
--exclude "**/*_socket" \
--exclude "**/*.sock" \
--exclude "**/virtualenv/" \
--exclude "**/.virtualenvs/" \
--exclude "**/__pycache__/" \
--exclude "**/dev/container/***" \
--exclude "**/dev/**/*.bin" \
${HOME}/ ${BACKUP_DIR} > /dev/null

if [ "$1" = "-l" ];then
	echo -n "compressing backup..."
	backup_file_prefix="$(cd $(dirname "$BACKUP_DIR");pwd)/$(basename "$BACKUP_DIR")"
	backup_file=${backup_file_prefix}_$(date +%F.%H%M%S).tgz
	tar --use-compress-program=pigz -c -f $backup_file -C $BACKUP_BASE $BACKUP_NAME > /dev/null
	if ls ${backup_file_prefix}_*.tgz 1>/dev/null 2>&1;then
		ls -t ${backup_file_prefix}_*.tgz |tail -n +2 | xargs rm --
	fi
	echo "done. [$backup_file]" 

	ENCRYPT_DIR="$BACKUP_BASE/encrpyted_backups"
	if [ ! -d $ENCRYPT_DIR ];then mkdir -p $ENCRYPT_DIR;fi
	pushd $ENCRYPT_DIR > /dev/null
	encrypt_ssh.sh $backup_file
	ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2 | xargs rm --
	ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.key.enc |tail -n +2 | xargs rm --
fi
