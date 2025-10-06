#!/bin/zsh

set -e
source "$HOME/.zprezto/custom/functions/logdy"

if [ "$1" = "-l" ];then
	BACKUP_BASE=$HOME/Downloads/local_backups
	BACKUP_NAME=$(hostname)
	BACKUP_DIR="$BACKUP_BASE/$BACKUP_NAME"/
	if [ ! -d "$BACKUP_DIR" ];then mkdir -p "$BACKUP_DIR";fi
	PASSWORD_OPTION=''
	backup_dest='local'
elif [ "$1" = "-s" ];then
	BACKUP_DIR=$HOME/Documents/storagebox/backup/$(hostname)/home/
	mkdir -p "$BACKUP_DIR"
	PASSWORD_OPTION=''
	backup_dest='storagebox'
else
	BACKUP_DIR=backup@cloudy::Backup/$(hostname)/home/
	PASSWORD_OPTION="--password-file=$HOME/.ssh/backup.rsync"
	backup_dest='cloudy'
fi
current_dir=$(dirname $0)
filter_file="$(dirname "$current_dir")/backup_home.filter"

logdy info "backing up [$HOME]...to [$BACKUP_DIR]" destination="$backup_dest"
echo '{"timestamp":'$(date +%s)', "dateString": "'$(date +%FT%T.%3N)'", "destination": "'$backup_dest'"}' | jq . > "$HOME/.last_backup"
"$current_dir"/git_remote_json.sh ~/dev | jq > ~/dev/git.backup

# https://serverfault.com/questions/279609/what-exactly-will-delete-excluded-do-for-rsync
rsync --timeout=90 --stats -i -a -r -v -tgo -p -l -D --update --no-links --no-specials --no-group --no-devices --delete-after --delete-excluded \
$PASSWORD_OPTION --filter="merge $filter_file" \
${HOME}/ ${BACKUP_DIR} | grep -v 'skipping non-regular file'

if [ "$1" = "-l" ];then
	logdy debug "compressing backup..." backup_dir="$BACKUP_DIR"
	backup_file_prefix="$(cd $(dirname "$BACKUP_DIR");pwd)/$(basename "$BACKUP_DIR")"
	backup_file=${backup_file_prefix}_$(date +%F.%H%M%S).tgz
	tar --use-compress-program=pigz -c -f $backup_file -C $BACKUP_BASE $BACKUP_NAME > /dev/null
	if [ $(ls -t ${backup_file_prefix}_*.tgz |tail -n +2|wc -l) -gt 1 ];then
		ls -t ${backup_file_prefix}_*.tgz |tail -n +2 | xargs rm --
	fi
	logdy debug "done. [$backup_file]" backup_file="$backup_file"

	ENCRYPT_DIR="$BACKUP_BASE/encrpyted_backups"
	if [ ! -d $ENCRYPT_DIR ];then mkdir -p $ENCRYPT_DIR;fi
	pushd $ENCRYPT_DIR > /dev/null
	~/.zprezto/custom/bin/encrypt_ssh.sh $backup_file
	if [ $(ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2|wc -l) -gt 1 ];then
		ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.enc |tail -n +2 | xargs rm --
		ls -t $ENCRYPT_DIR/${BACKUP_NAME}_*.tgz.key.enc |tail -n +2 | xargs rm --
	fi
fi
