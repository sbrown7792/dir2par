# dir2par
recurses through a directory, and makes a matching directory structure full of par2 files for the original files

very simple, probably terribly broken. don't use. There's no "rm" command in the script (yet) but it will still probably erase all your data, convert your 401k to dogecoin, and send all your explicit photos to your workplace's distribution list. 

I made this, like, 5 years ago? and am just uploading it now. I predict another 5-10 years will pass before I make another commit. Hi future old me! Nice white hair you got there. 

## Update 27NOV2022
The script at least creates the par2 files, and will verify your source directory based on them, so I feel comfortable making this public now. 

Usage: `./dir2par.sh SOURCE_DIR DEST_DIR OPERATION`

Where: 
* `SOURCE_DIR` is the directory containing files you want to create par2 verification/repair files for
* `DEST_DIR` is a directory where you want to store the par2 files (the script creates a mirrored directory structure, with each source file becoming a directory containing the associated par2 files
* `OPERATION` is either "create" or "verify" to either create new par2 files (overwriting any existing) or verify source files based on existing par2 files.

If your data is growing, make sure you run "create" every so often to create the par2 files for any new files you've added since running last. But I'd recommend to do a "verify" first, because if a source file is corrupted between the two "create" runs, the second one will create new par2 files based on the corrupted source file. This is an enhancement I'd like to get around to fixing, but as you can tell from my original readme file, it might be awhile. Yes, I have (some) white hair...
