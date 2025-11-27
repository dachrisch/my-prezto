#!/bin/bash
set -e

source "$HOME/.zprezto/custom/functions/logdy"

phone_folder=$1
backup_folder=$2

if [ $# -ne 2 ];then
	# https://www.maketecheasier.com/easily-mount-your-iphone-as-an-external-drive-in-ubuntu/
	echo "usage: $0 <phone folder> <backup folder>"
	exit 1
fi

if [ ! -d "$backup_folder" ];then
	logdy error "Backup folder doesn't exist" backup_folder="$backup_folder"
	exit 2
fi

backup() {
	source=$1
	destination=$2

	logdy info "Backing up" source="$source" destination="$destination"
	rsync -avzh "$source" "$destination"
}

logdy info "Pairing device"
idevicepair pair
logdy info "Unmounting" phone_folder="$phone_folder"
sudo umount -f "$phone_folder" || true
logdy info "Mounting" phone_folder="$phone_folder"
ifuse "$phone_folder"
# Camera Roll
backup "$phone_folder/DCIM" "$backup_folder/"
# Old Photo location
backup "$phone_folder/PhotoData" "$backup_folder/"
