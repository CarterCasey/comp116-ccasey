# PadCrypt #

This is my proof-of-concept implementation for a usb passkey. The goal is to have a command line tool that lets you link a directory in your machine with a USB drive (that has more than 1GB memory). The tool should encrypt your files using a one-time pad stored on the USB drive. When the USB is removed, the decrypted files are also removed. When the USB is mounted, the encrypted files are subsequently encrypted. Currently it's mostly hacked together with bash scripts, and hasn't been tested on many machines, but it certainly works on mine.  

WARNING: This does use a one-time pad encryption, so if you use this software on actual sensitive data, losing the usb means losing the files.  

### setup.sh ###

To use the software, simply copy the pad-crypt directory from my securpity git-repo, then run `bash setup.sh`. This will do the following things:  

1. Compile otpad, the one-time padder I wrote in c to deal with the low level encryption.  
2. Set up the profile files in your home directory so that they start the encryptiong daemon on login, and update your path so you can use the included executables.  
3. Copy the pad-crypt directory into your home directory as `~/.pad_crypt`, then link the necessary executables to the `~/.pad_crypt/bin` directory for your use.  

After this you should be able to use the software. The tool you use for this is  

### pcrypt ###

After running `bash setup.sh`, this tool should be available on your executable path. You can run it interactively, getting prompts for which disk should hold the pad, which directory should hold the encrypted files, and how many of those files you'd like cleaned out when the disk is ejected. Alternatively you can use the command-line, though I don't have it set up to parse flags at the moment, so arguments have to come in order. Running `pcrypt -h` lets you see the order.  

Note: Make sure you don't have any files with the .pcrypt extension in your encryption directory when you first run pcrypt, and that you have just the files you want in that directory when pcrypt gets run. It would be better to let pcrypt update how the directory is managed dynamically, but right now it's just a proof-of-concept and doesn't have that functionality.

#### otpad ####

This is a pretty simple program, written in c, that lets you use one-time pad encryption. It's used by the PadCrypt software, but I put it in the command-path in case you'd like to manage some padding yourself.  

## TODO ##

1. Documentation. It's pretty severely lacking. All the professors I had for the intro progression would - and should - be appalled.  
2. Better command-line interface. I describe this a bit above.  
3. More secure framework. Right now most of the functionality is managed with bash scripts, of which I can't vouch for the security strength. The otpad executable is in c and should be pretty damn secure, especially if run separately with the -s flag.  
4. GUI? I don't have any experience with this, but it'd be a nice touch.

