#!/bin/bash

source utils.sh

if [ "$1" != "-n" ]; then
	# Compile the code for otpad
	if [ ! -f "otpad" ]; then
		bash compile.sh
	fi

	# Update path and profile appropriately
	echo "Updating files in home directory"

	if [ -f "$HOME/.bash_profile" ]; then
		if ! cat ~/.bash_profile | grep -qe 'source ~/.profile'; then
			echo 'source ~/.profile' >> ~/.bash_profile
		fi
	elif [ -f "$HOME/.bashrc" ]; then
		if ! cat ~/.bashrc | grep -qe 'source ~/.profile'; then
			echo 'source ~/.profile' >> ~/.bash_profile
		fi
	fi

	touch ~/.profile
	if ! cat ~/.profile | grep -qe 'PATH='; then
		echo PATH="$PATH:~/.pad_crypt/bin" >> ~/.profile
	fi
	if ! cat ~/.profile | grep -qe 'usbkeyd'; then
		echo 'if [ `ps aux | grep bin/usbeyd | wc -l` -gt 1 ]; then (nohup usbkeyd 0<&- &>/dev/null &) & fi' >> ~/.profile
	fi

	if [ ! -d "$HOME/.pad_crypt" ]; then
		mkdir ~/.pad_crypt

		cp -r ./* ~/.pad_crypt
		cd ~/.pad_crypt

		mkdir bin
		cd bin
		ln -s ../otpad .
		ln -s ../usbkeyd.sh ./usbkeyd
		chmod +xu *
	fi
fi

cd ~/.pad_crypt
	
echo -n "Enter mount directory of a disk to install PadCrypt: "
read disk
if [ ! -d "$disk" ]; then
	echo "$disk: No such directory" 1>&2
	echo -n "Disks are mounted on /Volumes/ for mac, " 1>&2
	echo "and /dev/ for linux. Try again with bash setup.sh -n" 1>&2
	exit 1
fi

if [ ! -f "$disk/.pad" ]; then 
	echo "Creating 1GB pad file. This could take some time."
	./otpad -n $disk/.pad 1024000
fi


touch $disk/."`makeSalt`"

echo -n "Enter directory of files to encrypt: "
read cryptdir

if [ ! -d "$cryptdir" ]; then
	cryptdir=${cryptdir/#~/$HOME}
	cryptdir=${cryptdir/#'$HOME'/$HOME}
fi

if [ ! -d "$cryptdir" ]; then
	echo "$cryptdir: No such directory" 1>&2
	exit 1
fi

echo $cryptdir >> $disk/.crypt-dir

for f in $cryptdir/*; do
	if ! isPcrypt "$f" && [ ! -f "$f".pcrypt ]; then
		# Should be secure even with empty password
		yes | ./otpad -p "`makeSalt`" $disk/.pad "$f" "$f".pcrypt
	fi
done

PATH="$PATH:~/.pad_crypt/bin"

(nohup usbkeyd 0<&- &> /dev/null &) &
