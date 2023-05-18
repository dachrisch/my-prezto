#!/bin/zsh

if [ -z $1 ];then
	echo "usage: $0 <basedir>"
	exit 1
fi
base_dir=$1

git_repo() {
  git_dir=$1
  working_dir=$(dirname "$git_dir")
  remote_output=$(git --git-dir=$git_dir --work-tree=$working_dir remote -v)
  json_output=$(echo "$remote_output" | awk 'BEGIN{ORS=","} {print "{\"name\": \"" $1 "\", \"url\": \"" $2 "\", \"action\": \"" substr($3, 2, length($3)-2) "\"}"}' | sed 's/,$//')
  dir_output="{\"dirname\": \"${working_dir//$HOME/~}\", \"remotes\": [$json_output]}"
  echo "$dir_output"
}

git_info_array=()

find "$base_dir" -type d -name .git | while read git_dir; do
  git_info_array+=("$(git_repo "$git_dir")")
done

echo $(IFS=, ; echo "[${git_info_array[*]}]")
