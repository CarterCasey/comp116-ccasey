Carter Casey and Macgill Davis

## Part 1 - Images: ##

After downloading the image files, it was quickly determined that b.jpg was the different image file - using `ls -l`, we can see that the size of that file was smaller than the other two.  
Since we were dealing with a jpg file, the data was probably embedded with steghide, we attempted to use the user passwords we had cracked from the disk. Finding that these were unrelated, the next attempt was to brute force using steghide's -p flag and a simple loop over the lines in metasploit's wordlists. I've included the script used to do this, called `stegloop`, in this directory. Note that it loops over the files in parallel, made possible by the shortness of the files used, and the fact that we had access to the multi-core Halligan servers.  
Cracking the password (which was `disney`) revealed a hidden executable called `runme`. Running `runme` prompted the user to enter their first name as an argument, which simply produced an encouraging message. However, upon further inspection using the `strings` command, it was possible to see that the executable had a deeper functionality. Passing the argument "blinky_the_wonder_chimp" to `runme` prompts the user to email you with a message.

## Part 2 - Disk: ##

1. What is/are the disk format(s) of the disk on the suspect's computing device?  
	* The `C:/` file system is in fat16 format. It's actually the base files needed to boot up a raspberry pi.
	* The `/2/` file system is in ext4 format.

2. Is there a phone carrier involved?  
	No. The disk itself is not a phone's disk. There's a ringtone stored on this disk, but the acutual OS and disk are not phone related. It's actually a raspberry pi.

3. What operating system, including version number, is being used? Please elaborate how you determined this information.  
	The OS is Kali GNU/Linux 1.0, debian.  
	I looked in the /etc/os-release file to find that information.

4. What applications are installed on the disk? Please elaborate how you determined this information.  
	Looking in /bin, /usr/bin, and /usr/local/bin, it seems there are many applications specific to the kali applications suite. There are also the standard linux apps installed.

5. Is there a root password? If so, what is it?  
	Yes. It is `princess`.

6. Are there any additional user accounts on the system? If so, what are their passwords?
	Yes. They are  
	* User: `judas`, Pass: `00000000`
	* User: `alejandro`, Pass: `pokerface`
	* User: `stefani`, Pass: `iloveyou`

7. List some of the incriminating evidence that you found. Please elaborate where and how you uncovered the evidence.  
	Using programs in the sleuthkit as well as autopsy, we were able to extract and recover nearly all of the files on the subjects disk. I've included the script used to recreate the disks, `makedisk.sh`, in this directory. It requires that sleuthkit be installed to run.  
	The subject has several pictures of a young Lady Gaga, as well as recordings of the singer. While this alone is not enough to incriminate, his posession of a schedule of times and places the singer was planning to be (as well as the obsession demonstrated by the subject's choice of usernames and passwords) add up to a higher degree of incrimination.

8. Did the suspect move or try to delete any files before his arrest? Please list the name(s) of the file(s) and any indications of their contents that you can find.  
	Yes. The `.bash_history` file in `/home/alejandro` reveal that the files `a15.jpg`, `a16.jpg`, and `a17.jpg` were recently deleted from user `alejandro`'s home directory. This is also confirmed by the `fls` command in the sleuthkit, though `icat` cannot recover the image files.  
	The `.bash_history` file in `/home/stefani` also reveals that the file `note.txt` was recently deleted, though `fls` did not reveal this file.

9. Did the suspect save pictures of the celebrity? If so, how many pictures of the celebrity did you find? (including any deleted images)  
	There are 14 non-deleted images, and 3 deleted images, for a total of 17 images of the celebrity.  
	Using the program `foremost`, we recovered all readable jpg files from the disk. After matching the images of Lady Gaga to those existing in user `alejandro`'s directory, we found that two of the deleted images had been recovered. They are included in this directory under the names `recovered-1.jpg` and `recovered-2.jpg`.

10. Are there any encrypted files? If so, list the contents in the encrypted file and provide a brief description of how you decrypted the file.  
	There was an encrypted file named `lockbox.txt`, which could be unzipped with the password gaga to produce a video file called edge.mp4 - this was the video of a radio perfomance Lady Gaga did of the song "The Edge of Glory."  
	The file was decrypted using fcrackzip, a utility that uses wordlists (or brute-force) to reveal the password used to encrypt zip files.

11. Does the suspect want to go see this celebrity? If so, note the date(s) and location(s) where the suspect wanted see to the celebrity.  
	* 12/31/2014: The Chelsea at the Cosmopolitan of Las Vegas Las Vegas, NV 9:00 p.m. PST
	* 2/8/2015: Wiltern Theatre, Los Angeles, CA, 9:30 p.m. PST
	* 5/30/2015: Hollywood Bowl, Hollywood, CA, 7:30 p.m. PDT

12. Who is the celebrity that the suspect has been stalking?  
	Lady Gaga (Stefani Joanne Angelina Germanotta)
