#!/bin/bash

source utils.sh

# Prints the names of all locally mounted disks
diskNames () {
	df -l | tail -n +2 | awk '{printf "%s\n", $NF}'
}

hasSalt() {
	disk=$1
	salt=`makeSalt`
	return [[ -f $d/."$salt" ]]
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

diskAdded () {
	disk="$1"
	for cryptdir in `find "$disk" -name ".pad" | sed -e "s/\.pad$//"`; do
		decrypt $cryptdir
	done
}

diskRemoved () {
	disk="$1"
	paths="$2"
	for pair in $paths; do
		old_disk=`echo $pair | cut -d: -f1`
		target_dir=`echo $pair | cut -d: -f2`

		if [ "$disk" = $old_disk ]; then
			for f in `tail n +2 $target_dir/.crypt-config`; do
				rm -f $target_dir/$f
			done
			return 0
		fi
	done 
	return 1
}

disks=""

while true; do
	updated_disks=`diskNames`

	if [ "$disks" != "$updated_disks" ]; then
		for d in $disks; do
			# if disk from old list not in new
			if hasSalt $d && echo $updated_disks | grep -qv "$d"; then
				diskRemoved $d $paths
				paths=`cleanPaths $updated_disks $paths`
			fi
		done

		for d in $updated_disks; do
			# if disk from new list not in old
			if hasSalt $d && echo $disks | grep -qv "$d"; then
				paths="$paths $d:`diskAdded $d`"
			fi
		done

		disks="$updated_disks"
	fi

	sleep 5
done
