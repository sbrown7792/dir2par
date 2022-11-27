#!/bin/bash

# why am i writing this im so damn tired

#fucking recursion coming right up
#...maybe

#dir2par.sh SRCDIR DSTDIR OPERATION

#get options
# - Source file directory
# - Dest directory
# - create, verify, or repair?
# - dry-run?
# - any par2 options

if [[ -d $1 ]]; then
	SRC=`realpath $1`
else
	echo "Error! Source directory $1 not found"
	exit
fi

if [[ -d $2 ]]; then
	DST=`realpath $2`
else
	DST=$2
	echo "Destination directory $DST does not exist, creating it"
	mkdir -p $DST
#	echo "Error! Directory $2 not found"
#	exit
fi

if [[ -n $3 ]]; then
	OPERATION=$3
else
	echo "Error, no operation specified"
	exit
fi

#comment out the "default" for now so i can add in the operation argument without having to figure out get-opts
#[[ -z $2 ]] && DST=".$SRC-par" || DST=$2

#if [[ ! -d $DST ]]; then
#	echo "Directory $DST does not exist, creating it"
#	mkdir -p $DST
#fi

CREATE_PAR () {
	#dynamically calculate block size given the filesize (2%, gives 5 blocks per file, for speed and size efficiency)
	local BLOCK_SIZE=$(( $(( $(( `ls -al "$FILE" | awk '{ print $5 }'` / 50 )) / 2048 + 1 )) * 2048 ))

	#perform the par, 10% redundancy, use 512MB of RAM (the default of 16M is stupid slow)
	par2 create -qq -s$BLOCK_SIZE -r10 -m512 "$FILE" > /dev/null

	#get the final destination of the par2 files, and move them there
	local PAR2FILES_DST=`echo "$FILE" | sed "s@$SRC@$DST@"`
	mkdir -p "$PAR2FILES_DST"
	mv "$FILE"*\.par2 "$PAR2FILES_DST"
}

VERIFY_FILE () {
	#get the parent directory of the source file
	local PARENT_DIR=`dirname $FILE`

	#get the par2 verification filename of the source file
	local PAR2_FILE=`echo "$FILE" | sed "s@$SRC@$DST@"`/`basename $FILE`.par2

	FILE_STATUS=`par2 verify -B $PARENT_DIR $PAR2_FILE`

	if [[ $FILE_STATUS == *"All files are correct, repair is not required"* ]]; then
		echo -n "  GOOD"
	else
		echo "  CORRUPT"
		NUM_CORRUPT=$(( $NUM_CORRUPT + 1 ))
	fi
}


NUM_FILE=0
NUM_FILES=`find $SRC -type f | grep -v ".par2$" | wc -l`
NUM_CORRUPT=0

IFS=$'\n'
for FILE in `find $SRC -type f | grep -v ".par2$"`
do
	# FILE is now an absolute path to the source file we need to operate on
	#count up the files
	NUM_FILE=$(( $NUM_FILE + 1 ))
	PERCENT_FILE=$(($(( $NUM_FILE * 100 )) / $NUM_FILES ))
	FRIENDLY=`echo "$FILE" | awk -F'/' '{ print $NF }'`
	echo -ne $'\r\e[K'
	echo -n "$PERCENT_FILE% Complete: Processing $FRIENDLY"

	if [[ $OPERATION == "create" ]]; then
		if [[ -s $FILE ]]; then
			CREATE_PAR
		fi
	fi
	if [[ $OPERATION == "verify" ]]; then
		if [[ -s $FILE ]]; then
			VERIFY_FILE
		fi
	fi

done

echo
# get list of files in source directory (relative path from here, recursively)
# iterate through list, prepending the dest directory name before the filepath for the par2 destination option (and create that folder first)
# ...done?
if [[ $OPERATION == "verify" ]]; then
	if [[ $NUM_CORRUPT -eq 0 ]]; then
		echo "All files checked out OK!"
	else
		echo "$NUM_CORRUPT corrupted files detected :("
	fi
fi
