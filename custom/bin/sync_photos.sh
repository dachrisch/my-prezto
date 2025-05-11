#!/bin/bash

# Script to sync photos from storagebox to $HOME/photo/
# Uses rsync with safe options and error handling

SOURCE="/mnt/storagebox/photo/"
DEST="$HOME/photo/"
LOGFILE="$HOME/sync_photos.log"

# Function: graceful exit with message and code
exit_with_message() {
    echo "$(date +'%F %T') - $1" | tee -a "$LOGFILE"
    exit "$2"
}

# Check if source directory exists
if [[ ! -d "$SOURCE" ]]; then
    exit_with_message "ERROR: Source directory $SOURCE does not exist." 1
fi

# Check if destination directory exists, if not create it
if [[ ! -d "$DEST" ]]; then
    echo "$(date +'%F %T') - Destination directory $DEST not found. Creating it." | tee -a "$LOGFILE"
    mkdir -p "$DEST" || exit_with_message "ERROR: Failed to create destination directory $DEST." 2
fi

# Run rsync
echo "$(date +'%F %T') - Starting rsync from $SOURCE to $DEST" | tee -a "$LOGFILE"
rsync -rav --safe-links --prune-empty-dirs --delete-after "$SOURCE" "$DEST" >> "$LOGFILE" 2>&1

# Check rsync exit code
if [[ $? -ne 0 ]]; then
    exit_with_message "ERROR: rsync failed during sync." 3
fi

# Success message
exit_with_message "Sync completed successfully." 0
