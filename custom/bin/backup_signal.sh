#!/bin/zsh

set -e
source "$HOME/.zprezto/custom/functions/logdy"

# Determine backup location based on argument
if [ "$1" = "-l" ]; then
    BACKUP_BASE=$HOME/Downloads/local_backups/signal
    BACKUP_NAME=$(hostname)
    BACKUP_DIR="$BACKUP_BASE/$BACKUP_NAME/"
    mkdir -p "$BACKUP_DIR"
    PASSWORD_OPTION=''
    backup_dest='local'
elif [ "$1" = "-s" ]; then
    BACKUP_BASE=$HOME/Documents/storagebox/backup/signal
    BACKUP_NAME=$(hostname)
    BACKUP_DIR="$BACKUP_BASE/$BACKUP_NAME/"
    mkdir -p "$BACKUP_DIR"
    PASSWORD_OPTION=''
    backup_dest='storagebox'
else
    # Cloudy backup
    BACKUP_BASE=$HOME/Downloads/local_backups/signal/$(hostname)
    mkdir -p "$BACKUP_BASE"                  # local copy
    BACKUP_DIR=backup@cloudy::Backup/signal/$(hostname)/
    PASSWORD_OPTION="--password-file=$HOME/.ssh/backup.rsync"
    backup_dest='cloudy'
fi

# Temp directory for exporting messages
EXPORT_DIR=$(mktemp -d)

# Export Signal messages to export directory
logdy info "Exporting Signal messages using temporary export directory: $EXPORT_DIR..." export_dir="$EXPORT_DIR"
~/go/bin/sigtop export-messages -f json "$EXPORT_DIR"

# Temp directory for creating archive
ARCHIVE_TMP_DIR=$(mktemp -d)

# Create timestamped archive in separate temp directory
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="signal_messages_$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$ARCHIVE_TMP_DIR/$ARCHIVE_NAME"

tar -czf "$ARCHIVE_PATH" -C "$EXPORT_DIR" .

# Move archive locally first (for retention)
LOCAL_ARCHIVE_DIR="${BACKUP_BASE:-$BACKUP_DIR}"
mv "$ARCHIVE_PATH" "$LOCAL_ARCHIVE_DIR/"

logdy info "Local backup completed: ${LOCAL_ARCHIVE_DIR}/$ARCHIVE_NAME" archive_name="${LOCAL_ARCHIVE_DIR}/$ARCHIVE_NAME"

# Cloudy sync if applicable
if [[ "$backup_dest" == "cloudy" ]]; then
    # Ensure remote directory exists
    REMOTE_DIR=${BACKUP_DIR#*::}
    REMOTE_HOST=${BACKUP_DIR%%::*}

    rsync -avh $PASSWORD_OPTION "$LOCAL_ARCHIVE_DIR/$ARCHIVE_NAME" "$BACKUP_DIR"
    echo "Remote backup completed: $BACKUP_DIR$ARCHIVE_NAME"
fi

# Clean up temp directories
rm -rf "$EXPORT_DIR"
rm -rf "$ARCHIVE_TMP_DIR"

# --- Remove backups older than 30 days and report count ---
OLD_FILES=()
while IFS= read -r -d '' file; do
    OLD_FILES+=("$file")
done < <(find "$LOCAL_ARCHIVE_DIR" -maxdepth 1 -name "signal_messages_*.tar.gz" -type f -mtime +30 -print0)

COUNT=${#OLD_FILES[@]}

if (( COUNT > 0 )); then
    rm -f "${OLD_FILES[@]}"
    logdy info "Removed $COUNT old backup(s) from $LOCAL_ARCHIVE_DIR" count=$COUNT
else
    logdy debug "No old backups older than 30 days found in $LOCAL_ARCHIVE_DIR"
fi
