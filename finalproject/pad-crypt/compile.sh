#!/bin/bash
# Compiles and links the otpad program
#
# Author: Carter Casey

source utils.sh

FLAGS="-g -O1 -Wall -Wextra -std=c99"

if [ "$1" = "-d" ]; then
    FLAGS="$FLAGS -DDEBUG"
fi

if [ "`uname`" != "Darwin" ]; then
	LFLAGS="-lcrypt"
fi

if [ ! -f salt.h ]; then
	echo -n "Creating salt file. Salt is unique to each user. "
	echo "Recompiling as a different user will produce a different encryption."
	touch salt.h && chmod 600 salt.h
	echo 'const char* SALT = '\"`makeSalt`\"';' >> salt.h
fi

gcc $FLAGS -o otpad otpad.c $LFLAGS && chmod 700 otpad


