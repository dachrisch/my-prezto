#!/bin/zsh

pipe=/tmp/selecPipe

item=$1

count=0
located_files=()
options_array=()
locate $item | while read -r located_file;do
	echo $count $located_file
	options_array+=($count)
	options_array+="$located_file"
	located_files+="$located_file"
    ((count++))
done

mkfifo $pipe

dialog --title "Which file" --menu "Choose one" 0 0 17 ${options_array[@]} 2>$pipe&
clear

selection=$(cat $pipe)

if [ ! -z "$selection" ];then
	subl $located_files[$selection]
fi
