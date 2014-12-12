#!/bin/bash

source ~/.pad_crypt/utils.sh

# Prints the names of all locally mounted disks
diskNames () {
	df -l | tail -n +2 | awk '{printf "%s\n", $NF}'
}

hasSalt() {
	disk=$1
	salt=`makeSalt`
	if [ -f $d/."$salt" ]; then
		return 0
	else
		return 1
	fi
}

cleanPaths () {
	disks="$1"
	paths="$2"

	for pair in paths; do
		old_disk=`echo $pair | cut -d: -f1`
		if echo $disks | grep -qe $old_disk; then
			new_paths="$new_paths $pair"
		fi
	done
	echo "new_paths"
}

diskRemoved () {
	disk="$1"
	paths="$2"
	for pair in $paths; do
		old_disk=`echo $pair | cut -d: -f1`
		target_dir=`echo $pair | cut -d: -f2`

		if [ "$disk" = $old_disk ]; then
			while read -r f; do
				rm "$f"
			done < "$target_dir"/.clean-list
		fi
	done 
}

disks=""

while true; do
	updated_disks=`diskNames`

	if [ "$disks" != "$updated_disks" ]; then
		for d in $disks; do
			# if disk from old list not in new
			if echo $updated_disks | grep -qv "$d"; then
				diskRemoved $d $paths
				paths=`cleanPaths $updated_disks $paths`
			fi
		done

		for d in $updated_disks; do
			# if disk from new list not in old
			if hasSalt $d && ! echo $disks | grep -qe "$d"; then
				new_path=`decrypt "$d"`
				paths="$paths $d:$new_path"
			fi
		done

		disks="$updated_disks"
	fi

	sleep 5
done
