#!/bin/bash

makeSalt() {
	SALT="_${USER:0:4}${UID:0:2}${SHELL:5:2}"
	while test ${#SALT} -lt 9; do
		SALT="$SALT${SHELL:5:$((9 - ${#SALT}))}"
	done
	echo $SALT
}

isPcrypt () {
	if [ `echo $1 | sed -e "s/\./ /g" | awk '{printf $NF}'` = "pcrypt" ]; then
		return 0
	else 
		return 1
	fi
}

decrypt () {
	disk="$1"
	pushd .
	cd "$disk"

	# The most recently set crypt directory.
	target_path=`tail -n1 .crypt-dir`

	if [ ! -d "$target_path" ]; then 
		echo -n "Crypt file doesn't exist! Make a new " > .crypt-err
		echo "one with ./setup.sh -n <path-to-directory>" > .crypt-err
		exit 1
	fi

	cd $target_path

	for f in *; do
		if isPcrypt "$f"; then
			plain=`echo "$f" | sed -e "s/\.pcrypt$//"`
			if [ ! -f "$plain" ]; then
				yes | otpad -p "`makeSalt`" "$disk"/.pad "$f" "$plain" 2> /dev/null
			fi
		fi
	done
	popd

	echo $target_path
}
