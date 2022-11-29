#!/bin/bash


#dir2par.sh SRCDIR DSTDIR OPERATION

#get options
# - Source file directory
# - Dest directory
# - create, verify, or repair?
# - dry-run?
# - any par2 options

#make sure par2 exists
DOES_PAR_EXIST=`which par2`
if [[ -z $DOES_PAR_EXIST ]]; then
	echo "par2 command not found in PATH. Please install (apt install par2)"
	exit
fi

#count arguments, make sure we have three (again, just a stopgap until i figure out getopts)
if [ "$#" -ne 3 ]; then
	echo "Script needs exactly three arguments"
	echo "Please provide exactly the SOURCE_DIR, DEST_DIR, and OPERATION"
	echo
	echo "Example: ./dir2par.sh /path/to/source/data/ /path/to/store/par2/files/ create"
	echo "Example: ./dir2par.sh /path/to/source/data/ /path/to/existing/par2/files/ verify"
	exit
fi

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

	#make sure PAR2 file exists before trying to verify...
	if [[ -f $PAR2_FILE ]]; then
		FILE_STATUS=`par2 verify -B $PARENT_DIR $PAR2_FILE`

		if [[ $FILE_STATUS == *"All files are correct, repair is not required"* ]]; then
			echo -n "  GOOD"
			NUM_GOOD=$(( NUM_GOOD + 1 ))
		else
			#corrupt file, determine if repair is possible
			RECOVERABLE=`echo $FILE_STATUS | grep -o "You have.*Repair is.*possible."`
			echo "  CORRUPT: $RECOVERABLE"

			if [[ $RECOVERABLE == *"Repair is possible"* ]]; then
				#provide the user with the command to repair
				echo "Repair command: par2 repair -B $PARENT_DIR $PAR2_FILE"
				NUM_REPAIRABLE=$(( NUM_REPAIRABLE + 1 ))
			else
				NUM_UNRECOVERABLE=$(( NUM_UNRECOVERABLE + 1 ))
			fi
			NUM_CORRUPT=$(( NUM_CORRUPT + 1 ))
		fi
	else
		echo " - no par2 file available!"
		NUM_MISSING_PAR2=$(( NUM_MISSING_PAR2 + 1 ))
	fi
}


NUM_FILE=0
NUM_FILES=`find $SRC -type f | grep -v ".par2$" | wc -l`
NUM_GOOD=0
NUM_CORRUPT=0
NUM_REPAIRABLE=0
NUM_UNRECOVERABLE=0
NUM_MISSING_PAR2=0
NUM_ZERO_FILES=0

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

	if [[ -s $FILE ]]; then
		case $OPERATION in
			"create")
				CREATE_PAR
				;;
			"verify")
				VERIFY_FILE
				;;
		esac
	else
		echo " - zero-byte file, skipping! (can't protect/verify/repair a file with no data)"
		NUM_ZERO_FILES=$(( NUM_ZERO_FILES + 1 ))
	fi

done

echo
# get list of files in source directory (relative path from here, recursively)
# iterate through list, prepending the dest directory name before the filepath for the par2 destination option (and create that folder first)
# ...done?
if [[ $OPERATION == "verify" ]]; then
	QUANTIFIER=""
	echo
	echo "Out of $NUM_FILES source files:"
	if [[ $NUM_MISSING_PAR2 -ne 0 ]]; then
		echo " * $NUM_MISSING_PAR2 source files have no par2 files. (When was the last time you ran the \`create\` operation?)"
		QUANTIFIER=" other"
	fi
	echo
	if [[ $NUM_ZERO_FILES -ne 0 ]]; then
		echo " * $NUM_ZERO_FILES zero-byte files were found in the source directory."
		QUANTIFIER=" other"
	fi
	echo
	if [[ $NUM_CORRUPT -ne 0 ]]; then
		echo " * $NUM_CORRUPT corrupted files detected."
		echo " **** $NUM_REPAIRABLE are able to be repaired!"
		echo " **** $NUM_UNRECOVERABLE are unrecoverable :("
	fi
	echo
	if [[ $NUM_GOOD -ne 0 ]]; then
		echo " * All$QUANTIFIER files ($NUM_GOOD) checked out OK!"
	else
		echo " * No files verified."
	fi
	echo
fi
