#!/bin/sh
set -e

phone_folder=$1
backup_folder=$2

if [ $# -ne 2 ];then
	# https://www.maketecheasier.com/easily-mount-your-iphone-as-an-external-drive-in-ubuntu/
	echo "usage: $0 <phone folder> <backup folder>"
	exit 1
fi

if [ ! -d "$backup_folder" ];then
	echo "folder [$backup_folder] doesn't exists"
	exit 2
fi

backup() {
	source=$1
	destination=$2

	echo "Backing up [$source] to [$destination]..."
	rsync -avzh "$source" "$destination"
}

echo "pairing device..."
idevicepair pair
echo "unmounting [$phone_folder]..."
sudo umount -f "$phone_folder" || true
echo "mounting [$phone_folder]..."
ifuse "$phone_folder"
# Camera Roll
backup "$phone_folder/DCIM" "$backup_folder/"
# Old Photo location
backup "$phone_folder/PhotoData" "$backup_folder/"
