#!/bin/zsh

set +x

fail() {
	echo $1
	exit 1
}

delete_excessive=1
check_size=1
image_size=400
delete_small=0

while [ $# -gt 0 ]
	do
	# get parameters
	case "$1" in
		-nd)   # no delete
			   delete_excessive=0
			   ;;
		-nc)   # no check
			   check_size=0
			   ;;
		-s)    # size
			   shift
			   image_size=`expr "$1" : '\([0-9]*\)'`
			   ;;
		-ds)   # delete small
			   delete_small=1
			   ;;
		-rs)   # replace small
			   delete_small=2
			   ;;
		 -)    # STDIN and end of arguments
			   break
			   ;;
		-*)    # any other - argument
			   fail "--- UNKNOWN OPTION ---"
			   ;;
		*)     # end of arguments
			   break
			   ;;
	esac
	shift   # next option
done

dir=$1


[ -d "$dir" ] || fail "dir [$dir] not found"

entries=$(mktemp)

find $dir -name "*.JPG" -print > $entries
count=$(cat $entries | wc -l)
echo "trimming $count files in [$dir]..."

cat $entries | parallel -j 3 --eta --bar '[ -f {//}/trimmed_{/.}-000.jpg ] || (cd {//}; multicrop -b black {/} trimmed_{/.}.jpg) >/dev/null 2>/dev/null'

trimmed=$(find $dir -iname "trimmed_*.jpg" -type f |wc -l)

echo "trimmed $trimmed files."
echo "checking transformed images..."

if [ $delete_excessive = 1 ];then
	# find excessive images and mark smaller ones for deletion
	find $dir -type f -name 'IMG_*.JPG'|parallel --bar "[ -f {//}/trimmed_{/.}-001.jpg ] && du -b {//}/trimmed_{/.}-*.jpg | sort -n | head -n-1 | cut -f2-" | parallel --bar 'mv {} {//}/{/.}.del'
	find $dir -type f -name '*.del' | parallel --bar rm
	# move the remaining file to index 000
	find $dir -type f -regextype posix-extended -regex '.*trimmed_.*-[0-9][0-9][1-9].jpg'| parallel 'f={//}/{/.};mv {} ${f::-3}000.jpg'
else
	echo "skipped"
fi

echo "checking for possible errors..."

if [ $check_size = 1 ];then
	small_files=$(mktemp)
	find $dir -iname "trimmed_*.jpg" -type f | parallel --bar identify -format \'%w %h %i\\n\' {} | awk '$1<'$image_size' || $2<'$image_size|cut -d' ' -f3- > $small_files
	if [ $delete_small = 1 ];then
		echo "deleting small files..."
		cat $small_files | parallel --bar rm {}
	elif [ $delete_small = 2 ];then
		echo "replacing small files..."
		cat $small_files | parallel --bar 'f={/.}; cp {//}/${f:8:-4}.JPG {}'
	else
		cat $small_files
	fi
else
	echo "skipped"
fi

# to remove small transformed images (in case of error)
# find . -iname "trimmed_*.jpg" -type f | parallel --bar identify -format \'%w %h %i\\n\' {} | awk '$1<300 || $2<300'|cut -d' ' -f3-|parallel -v rm {}