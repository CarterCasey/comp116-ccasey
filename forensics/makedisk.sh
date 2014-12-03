#!/bin/bash

if [ -z $1 ]; then
	echo "Usage: bash makedisk.sh <disk>"
	exit 1
else
	disk=$1
fi

descriptors=`mmls $disk | grep "\d.:" | \
			 awk '{ printf "%s|%s\n", $3, $6 }'`

for d in $descriptors; do
	off=`echo $d | cut -d"|" -f1`
	name=`echo $d | cut -d"|" -f2`
	if fls -o $off $disk 2> /dev/null > /dev/null; then
		for path in `fls -o $off -rpD $disk | awk '{ print $NF }'`
		do
			mkdir -p disk/$name/$path
		done
		for line in `fls -o $off -rupF $disk | \
			sed -e "s/ \*//" -e "s/://" -e "s/(realloc)//" | \
			awk '{ printf "%s|%s\n", $2, $NF}'`; do
			inode=`echo $line | cut -d"|" -f1`
			path=`echo $line | cut -d"|" -f2`
			icat -o $off $disk $inode > disk/$name/$path
		done
		for line in `fls -o $off -rdpF $disk | \
			sed -e "s/ \*//" -e "s/://" -e "s/(realloc)//" | \
			awk '{ printf "%s|%s\n", $2, $NF}'`; do
			inode=`echo $line | cut -d"|" -f1`
			path=`echo $line | cut -d"|" -f2`
			icat -o $off -r $disk $inode > disk/$name/$path
		done
	fi
done