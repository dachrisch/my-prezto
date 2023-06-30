#!/bin/bash

for uppercase in "$@"
	do echo -n "$uppercase --> "
	lowercase=$(echo $uppercase | awk '{print tolower($0)}')
	mv "$uppercase" "$lowercase"
	echo "$lowercase"
done
