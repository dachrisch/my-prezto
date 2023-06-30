#!/bin/bash

set -e

shopt -s expand_aliases

usage() {
	echo "$0 <source> <dest> ['<extension list>']"
}


source_dir=$1
dest_dir=$2
# optional third argument, if not set, take default
backup_files=${3:-"png jpg heic mov mp4 gif jpeg"}

if [ ! -d "$source_dir" ];then
	echo "source is not a directory: $source_dir"
	usage
	exit 1
fi

if [ ! -d "$dest_dir" ];then
	echo "destination is not a directory: $dest_dir"
	usage
	exit 1	
fi

archive_dir="$dest_dir/archive/$(basename $source_dir)"
backup_dir="$dest_dir/.tmp/dropbox_backup_$(date +%Y%m%d%H%M%S)"
logfile=$dest_dir/log/synchronize_photos.log
lockfile=/var/tmp/synchronize_photos.lock

log_preface() {
	echo "[$(date -Iseconds)]: "
}

if [ ! -d "$(dirname $logfile)" ];then mkdir -p "$(dirname $logfile)";fi

exec > >(tee -a -i "$logfile") 2>&1


date -Iseconds > $lockfile

teardown() {
	rm -rf $backup_dir
	rm $lockfile
}

backup() {
	file_extension=$1
	find "$source_dir" -maxdepth 2 -type f -name \*.$file_extension -exec cp -p "{}" "$backup_dir" \;
}

archive() {
	file_extension=$1
	find "$source_dir" -maxdepth 2 -type f -name \*.$file_extension -exec mv "{}" "$archive_dir/" \;
}

count_files() {
	file_extension=$1
	echo $(find "$dest_dir" -maxdepth 3 -newercc "$lockfile" -name \*.$file_extension | wc -l)
}


echo $(log_preface) "[1/3] selecting old files to backup [$source_dir]"

mkdir -p "$backup_dir"


for extension in $backup_files;do
	backup $extension
done

files_to_backup_count=$(ls "$backup_dir" | wc -l)

# check if files have been selected
if [ $files_to_backup_count -eq 0 ];then
	echo $(log_preface) "nothing selected...done."
	teardown
	exit 0
else
	echo $(log_preface) "================= [$files_to_backup_count] files being selected for backup ($backup_dir) ================="
	echo $(log_preface) $(ls "$backup_dir")
	echo $(log_preface) "================================================================"
fi

echo $(log_preface) "[2/3] move files in source to matching directory in dest (year/month)"
exiftool '-filename<filemodifydate' '-filename<DateTimeOriginal' -d $dest_dir'/%Y/%m/%Y-%m-%d %H.%M.%S%%-c.%%e' -i '@eaDir' -r -progress "$backup_dir" || true


# check if files have been moved
remaining_files=$(ls "$backup_dir" | wc -l)
copied_files=0
for extension in $backup_files;do
	copied_files=$(( copied_files + $(count_files $extension) ))
done

if [ $remaining_files -eq 0 ] && [ $copied_files -eq $files_to_backup_count ];then
	echo $(log_preface) "all done. cleaning up..."
	if [ ! -d "$archive_dir" ];then mkdir -p "$archive_dir";fi
	for extension in $backup_files;do
		archive $extension
	done
	teardown
	echo $(log_preface) "done."
else
	echo $(log_preface) "some files failed to backup...check backup dir ($backup_dir)"
	echo $(log_preface) $(ls "$backup_dir")
	echo $(log_preface) "exit!"
	exit 2
fi

echo $(log_preface) "================= ($source_dir) listing after ================="
echo $(log_preface) $(ls "$source_dir")
echo $(log_preface) "================================================================"

