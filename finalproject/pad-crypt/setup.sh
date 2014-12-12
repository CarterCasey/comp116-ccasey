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
			echo 'source ~/.profile > /dev/null' >> ~/.bash_profile
		fi
	fi

	touch ~/.profile
	if ! cat ~/.profile | grep -qe 'PATH='; then
		echo 'PATH=$PATH:~/.pad_crypt/bin' >> ~/.profile
	fi
	if ! cat ~/.profile | grep -qe 'usbkeyd'; then
		echo 'if [ `ps aux | grep usbkeyd | wc -l` -le 1 ]; then (nohup usbkeyd 0<&- &>/dev/null &) & fi' >> ~/.profile
	fi

	if [ ! -d "$HOME/.pad_crypt" ]; then
		mkdir ~/.pad_crypt

		cp -r ./* ~/.pad_crypt
		cd ~/.pad_crypt

		mkdir bin
		cd bin
		ln -s ../otpad .
		ln -s ../usbkeyd.sh ./usbkeyd
		ln -s ../pcrypt.sh ./pcrypt
		chmod +xu *
	fi
fi


