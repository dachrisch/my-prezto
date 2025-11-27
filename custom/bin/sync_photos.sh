#!/bin/bash

# Script to sync photos from storagebox to $HOME/photo/
# Uses rsync with safe options and error handling

source "$HOME/.zprezto/custom/functions/logdy"

SOURCE="/mnt/storagebox/photo/"
DEST="$HOME/photo/"
LOGFILE="$HOME/sync_photos.log"

export LOGDY_ALSO_TO_FILE="$LOGFILE"

# Function: graceful exit with message and code
exit_with_message() {
    local level="error"
    if [[ "$2" -eq 0 ]]; then
        level="info"
    fi
    logdy "$level" "$1"
    exit "$2"
}

# Check if source directory exists
if [[ ! -d "$SOURCE" ]]; then
    exit_with_message "ERROR: Source directory $SOURCE does not exist." 1
fi

# Check if destination directory exists, if not create it
if [[ ! -d "$DEST" ]]; then
    logdy info "Destination directory not found - creating it" dest="$DEST"
    mkdir -p "$DEST" || exit_with_message "ERROR: Failed to create destination directory $DEST." 2
fi

# Run rsync
logdy info "Starting rsync" source="$SOURCE" dest="$DEST"
rsync -rav --safe-links --prune-empty-dirs --delete-after "$SOURCE" "$DEST" >> "$LOGFILE" 2>&1

# Check rsync exit code
if [[ $? -ne 0 ]]; then
    exit_with_message "ERROR: rsync failed during sync." 3
fi

# Success message
exit_with_message "Sync completed successfully." 0
