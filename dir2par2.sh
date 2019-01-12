#!/bin/bash

# why am i writing this im so damn tired

#fucking recursion coming right up
#...maybe



#get options
# - Source file directory
# - Dest directory
# - create, verify, or repair?
# - dry-run?
# - any par2 options

if [[ -d $1 ]]; then
	SRC=`realpath $1`
else
	echo "Error! Directory $1 not found"
	exit
fi

[[ -z $2 ]] && DST=".$SRC-par" || DST=$2

if [[ ! -d $DST ]]; then
	echo "Directory $DST does not exist, creating it"
	mkdir -p $DST
fi

NUM_FILE=0
NUM_FILES=`find $SRC -type f | grep -v ".par2$" | wc -l`

IFS=$'\n'
for FILE in `find $SRC -type f | grep -v ".par2$"`
do
	# FILE is now an absolute path to the source file we need to par
	#count up the files
	NUM_FILE=$(( $NUM_FILE + 1 ))
	PERCENT_FILE=$(($(( $NUM_FILE * 100 )) / $NUM_FILES ))
	FRIENDLY=`echo "$FILE" | awk -F'/' '{ print $NF }'`
	echo -ne $'\r\e[K'
	echo -n "$PERCENT_FILE% Complete: Processing $FRIENDLY"

	if [[ -s $FILE ]]; then

		#dynamically calculate block size given the filesize (2%, gives 5 blocks per file, for speed and size efficiency)
		BLOCK_SIZE=$(( $(( $(( `ls -al "$FILE" | awk '{ print $5 }'` / 50 )) / 2048 + 1 )) * 2048 ))
		
		#perform the par, 10% redundancy, use 512MB of RAM (the default of 16M is stupid slow)
		par2 create -qq -s$BLOCK_SIZE -r10 -m512 "$FILE" > /dev/null
		
		#get the final destination of the par2 files, and move them there
		PAR2FILES_DST=`echo "$FILE" | sed "s@$SRC@$DST@"`
		mkdir -p "$PAR2FILES_DST"
		mv "$FILE"*\.par2 "$PAR2FILES_DST"
		
	fi
	
done

echo 
# get list of files in source directory (relative path from here, recursively)
# iterate through list, prepending the dest directory name before the filepath for the par2 destination option (and create that folder first)
# ...done?
