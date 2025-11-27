#!/bin/bash
set -e

source "$HOME/.zprezto/custom/functions/logdy"

# extract pictures from phone, which are not in DCIM folder
phone_dir=$1
backup_dir=~/Downloads/local_backups/phone_pictures_tmp
dest_dir=~/Pictures/photo@cloudy/
filter_file="$(dirname $(dirname $0))/phone_pictures.filter"

if [ ! -d "$phone_dir" ];then
	logdy error "Phone directory does not exist" phone_dir="$phone_dir"
	exit 1
fi

if [ ! -d $backup_dir ];then
	mkdir $backup_dir
fi

logdy info "Backing up pictures from phone" phone_dir="$phone_dir"
printf 'source: \e]8;;file://%s\e\\%s\e]8;;\e\\\n' "$phone_dir" "$phone_dir"

rsync -h --progress -r -tgo -p -l -D --filter="merge $filter_file" --prune-empty-dirs "$phone_dir/" "$backup_dir"


if [ ! -d $dest_dir ];then
	logdy error "Destination does not exist" dest_dir="$dest_dir"
	exit 2
fi

logdy info "Deleting duplicates"
fdupes -Idq $backup_dir -r $dest_dir > /dev/null

logdy info "Moving pictures into destination" dest_dir="$dest_dir"
printf 'destination: \e]8;;file://%s\e\\%s\e]8;;\e\\\n' "$dest_dir" "$dest_dir"
exiftool '-filename<filemodifydate' '-filename<DateTimeOriginal' -d $dest_dir'/%Y/%m/%Y-%m-%d %H.%M.%S%%-c.%%e' -i '@eaDir' -r -progress "$backup_dir" || true
