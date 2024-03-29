#!/bin/bash

source ~/.pad_crypt/utils.sh

# TODO: Add command line flags and parsing

if [ "$1" = "-h" ]; then
	echo "Usage: pcrypt [<pad disk> [<crypt directory> [-a]]]"
	exit 0
fi

if [ -n "$1" ]; then
	disk="$1"
else
	echo -n "Enter the mount directory for the PadCrypt disk: "
	read disk
fi
if [ ! -d "$disk" ]; then
	echo "$disk: No such directory" 1>&2
	echo -n "Disks are mounted on /Volumes/ for mac, " 1>&2
	echo "and /media/ for (our) linux. Try again with bash setup.sh -n" 1>&2
	exit 1
fi


if [ ! -f "$disk/.pad" ]; then 
	echo "Creating 1GB pad file. This could take some time."
	./otpad -n $disk/.pad 1024000
fi

touch $disk/."`makeSalt`"

if [ -n "$2" ]; then
	cryptdir="$2"
else 
	echo -n "Enter directory of files to encrypt: "
	read cryptdir
fi
if [ ! -d "$cryptdir" ]; then
	cryptdir=${cryptdir/#~/$HOME}
	cryptdir=${cryptdir/#'$HOME'/$HOME}
fi

if [ ! -d "$cryptdir" ]; then
	echo "$cryptdir: No such directory" 1>&2
	exit 1
fi

echo $cryptdir >> $disk/.crypt-dir

if [ -f "$cryptdir"/.clean-list ]; then rm "$cryptdir"/.clean-list; fi

if [ "$3" = "-a" ]; then
	response="y"
else
	clean_all="false"
	echo -n "Would you like all unencrypted files in this directory to be "
	echo -n "deleted when the padcrypt disk is removed? (y/n): "
	read response
fi

if [ `echo ${response:0:1} | tr '[:upper:]' '[:lower:]'` = "y" ]; then
	clean_all="true"
else 
	loop="true"
	echo -n "Please enter any files you'd like to get deleted "
	echo "when the PadCrypt disk is removed."
	echo "(Press enter after every file, and end the list with END)"
	read entry || loop="false"
	while [ "$entry" != "END" ] && $loop; do
		echo $entry >> $cryptdir/.clean-list
		read entry || loop="false"
	done
fi

for f in $cryptdir/*; do
	if ! isPcrypt "$f" && [ ! -f "$f".pcrypt ]; then
		if $clean_all; then echo "$f" >> $cryptdir/.clean-list; fi
		# Should be secure even with empty password
		echo Encrypting "$f" ...
		yes | otpad -p "`makeSalt`" $disk/.pad "$f" "$f".pcrypt
	fi
done

echo "Files encrypted."

if [ `ps aux | grep bin/usbkeyd | wc -l` -le 1 ]; then
	(nohup usbkeyd 0<&- &> /dev/null &) &
fi
