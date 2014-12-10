#!/bin/bash

makeSalt() {
	SALT="_${USER:0:4}${UID:0:2}${SHELl:4:4}"
	while test ${#SALT} -lt 9; do
		SALT="$SALT${SHELL:0:$((9 - ${#SALT}))}"
	done
	echo $SALT
}

isPcrypt () {
	return [[ `sed -e "s/\./ /g" | awk '{printf $NF}'` = "pcrypt" ]]
}

decrypt () {
	pushd .
	cd "$1"

	target_path=`head -n1 .crypt-config`

	if [ ! -d $target_path ]; then mkdir $target_path; fi
	cp .crypt-config $target_path

	for f in `ls .`; do
		if isPcrypt $f; then
			plain=`echo $f | sed -e "s/\.pcrypt$//"`
			if [ ! -f $plain ]; then
				yes | otpad -p "" .pad $f $target_path/$plain 2>&1 > /dev/null
			fi
		fi
	done
	popd

	echo $target_path
}
