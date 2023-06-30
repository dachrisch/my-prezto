#!/bin/bash

set +e
current=0
all=$#
for _file in "$@";do 
	(( current++ ))
	echo -n "[$current/$all] $_file..."
	convert  "$_file" -resize 50% "res_$_file"
	echo "done."
done
