#define __PROGRAM_NAME "otpad"
#if ! defined(__APPLE__)
#define _POSIX_C_SOURCE 1
#define _XOPEN_SOURCE
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <termios.h>
#include <stdbool.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include "salt.h"
#include <pwd.h>

#define BUFF_FALLBACK 65536
#define MAX_PAD 0xFFFFFFFFUL
#define RESPONSE_SIZE 8
#define ALL_WRITE 0002
#define READ_SIZE 1024
#define MAX_PASS 32
#define MAX_NAME 32
#define HASH_LEN 20
#define SALT_LEN 9
#define ROOT_ID 0

#ifdef DEBUG
	#define DEBUGOUT(TEXT) \
		do { \
			fprintf(stderr, "%s\n", TEXT); \
		} while(false)
#else
	#define DEBUGOUT(TEXT)
#endif


void usage()
{
	fprintf(stderr, "Usage: ./otpad [-p <password>] [-s] ");
	fprintf(stderr, "<padfile> <infile> <outfile> ||\n");
	fprintf(stderr, "       ./otpad -n <padfile> <size-KB>\n");
	exit(EXIT_FAILURE);
}

void assertSys(int ret_val, char* func_name)
{
	if (ret_val != 0) {
		perror(func_name);
		exit(ret_val);
	}
}

void continuePrompt()
{
	char* response = malloc(2);
	fprintf(stderr, "Do you wish to proceed? (y/n) ");
	assertSys(fgets(response, RESPONSE_SIZE, stdin) == NULL, "fgets");
	if (response[0] != 'y' && response[0] != 'Y') {
		exit(EXIT_FAILURE);
	}
	free(response);
}

void getFileOwner(uid_t uid, char** name)
{
	struct passwd  pass_data;
	struct passwd* result;
	char* buffer;

	ssize_t buffer_size = sysconf(_SC_GETPW_R_SIZE_MAX);
	if (buffer_size == -1) {
		buffer_size = BUFF_FALLBACK;
	}

	buffer = malloc(buffer_size);
	assertSys(buffer == NULL, "malloc");

	assertSys(getpwuid_r(uid, &pass_data, buffer, buffer_size, &result),
			 "getpwuid_r");

	*name = malloc(MAX_NAME + 1);
	strncpy(*name, pass_data.pw_name, MAX_NAME + 1);

	free(buffer);
}

void isSecure(char* path)
{
	struct stat s;
	char* file_owner;

	assertSys(stat(path, &s), path);

	uid_t uid = getuid();
	if (s.st_uid != uid && uid != 0) {
		getFileOwner(s.st_uid, &file_owner);
		fprintf(stderr, "Warning: %s is owned by %s.\n", path,
				file_owner);
		continuePrompt();
	}

	if (s.st_mode & ALL_WRITE) {
		fprintf(stderr, "Warning: %s is writable by all users.\n",
				path);
		continuePrompt();
	}
}

void exists(char* path)
{
	if (! access(path, F_OK)) {
		fprintf(stderr, "Warning: File %s exists.\n", path);
		continuePrompt();
	}
	errno = 0;
}

void toggleEcho(FILE* stream)
{
	struct termios old, new;

	unsigned long echo = 0;
	int fd = fileno(stream);

	assertSys(tcgetattr(fd, &old), "tcgetattr");

	new = old;
	echo = old.c_lflag & ECHO;
	if (echo != 0) {
		new.c_lflag &= ~ECHO;
	} else {
		new.c_lflag |= ECHO;
	}

	assertSys(tcsetattr(fd, TCSAFLUSH, &new), "tcsetattr");
}

void getPassword(char** password_p)
{
	int pass_len = 0;
	printf("Enter password: ");

	toggleEcho(stdin);
	assertSys(fgets(*password_p, MAX_PASS + 2, stdin) == NULL, "fgets");
	toggleEcho(stdin);
	printf("\n");

	pass_len = strlen(*password_p);
	if ((*password_p)[pass_len - 1] == '\n') {
		(*password_p)[pass_len - 1] = '\0';
	} else {
		fprintf(stderr,
			"Error: Password is too long. It may be at most %d.\n",
			MAX_PASS);
		exit(EXIT_FAILURE);
	}
}

void transfer(char* from_name, char* to_name, size_t amount)
{
	FILE* from = fopen(from_name, "r");
	FILE* to = fopen(to_name, "w");

	char* buffer = malloc(READ_SIZE);

	for (size_t i = 0; i < amount; i++) {
		fread(buffer, 1, READ_SIZE, from);
		fwrite(buffer, 1, READ_SIZE, to);
	}

	free(buffer);
}

void newPad(char* pad_name, char* size_str)
{
	char* end;
	size_t pad_size = strtoul(size_str, &end, 10);

	if (end == size_str || *end != '\0') {
		fprintf(stderr,
			"Error: %s is not a valid pad size.\n", size_str);
		exit(EXIT_FAILURE);
	} else if (pad_size > MAX_PAD) {
		fprintf(stderr,
			"Error: Pad size %lu too large; maximum is %lu\n",
				pad_size, MAX_PAD);
		exit(EXIT_FAILURE);
	}

	exists(pad_name);

	transfer("/dev/urandom", pad_name, pad_size);
}

off_t fileSize(char* file_name)
{
	struct stat file_status;
	assertSys(stat(file_name, &file_status), file_name);

	return file_status.st_size;
}

char* makeHashPad(char* pass)
{
	char* salt = malloc(SALT_LEN + 1);
	char* hash_pad = malloc(READ_SIZE + 1);
	salt[0] = '_';
	for (int i = 1; i < 5; i++) {
		salt[i] = SALT[i + 4];
		salt[9 - i] = SALT[i];
	}

	char* hash = crypt(crypt(pass, salt), salt);

	for (int i = 0; i < READ_SIZE / HASH_LEN; i++) {
		strncat(hash_pad, hash, HASH_LEN);
		hash = crypt(crypt(hash, salt), salt);
	}
	strncat(hash_pad, hash, READ_SIZE % HASH_LEN);

	free(salt);
	return hash_pad;
}

void xor(char** buffer_p, char* a, char* b, size_t len)
{
	for (size_t i = 0; i < len; i++) {
		(*buffer_p)[i] = a[i] ^ b[i];
	}
}

void xorTransfer(FILE* pad, FILE* in, FILE* out, char* pass, off_t len)
{
	size_t rd_len = 0;
	char* in_buffer = malloc(READ_SIZE + 1);
	char* pad_buffer = malloc(READ_SIZE + 1);

	char* hash_pad = makeHashPad(pass);

	for (int i = 0; i < len / READ_SIZE + 1;) {
		rd_len = (READ_SIZE * ++i < len) ? READ_SIZE : len % READ_SIZE;
		assertSys(fread(in_buffer, 1, rd_len, in) != rd_len,
			 "fread(in-file)");
		xor(&in_buffer, hash_pad, in_buffer, rd_len);
		assertSys(fread(pad_buffer, 1, rd_len, pad) != rd_len,
			 "fread(pad-file)");
		xor(&pad_buffer, in_buffer, pad_buffer, rd_len);
		fwrite(pad_buffer, 1, rd_len, out);
	}

	free(hash_pad);
	free(in_buffer);
	free(pad_buffer);
}

void padCrypt(char* pad_name, char* in_name, char* out_name, char* pass)
{
	off_t pad_size = fileSize(pad_name);
	off_t in_size  = fileSize(in_name);

	if (pad_size == 0) {
		fprintf(stderr, "Error: Pad %s is empty.\n", pad_name);
		fprintf(stderr, "Use -n to make a new pad.\n");
		exit(EXIT_FAILURE);
	} else if (pad_size < in_size) {
		fprintf(stderr, "Error: Pad %s is smaller than file %s\n",
				pad_name, in_name);
		exit(EXIT_FAILURE);
	}

	FILE* pad = fopen(pad_name, "r");
	FILE* in  = fopen(in_name,  "r");
	FILE* out = fopen(out_name, "w");

	xorTransfer(pad, in, out, pass, in_size);
}

int main(int argc, char* argv[])
{
	errno = 0;

	char* pad_name = NULL;
	char* infile_name = NULL;
	char* outfile_name = NULL;
	char** names[] = {&pad_name, &infile_name, &outfile_name};
	int name_index = 0;

	bool safe_mode = false;

	char* password = malloc(MAX_PASS + 1);
	password[0] = '\0';

	if (argc == 4 && (! strcmp(argv[1], "-n"))) {
		newPad(argv[2], argv[3]);
		exit(EXIT_SUCCESS);
	} else if (argc > 7) {
		fprintf(stderr, "Error: Too many arguments\n");
		usage();
	} else if (argc < 4) {
		fprintf(stderr, "Error: Too few arguments.\n");
		usage();
	}

	for (int i = 1; i < argc; i++) {
		if (! strcmp(argv[i], "-p")) {
			if (argv[++i][0] == '\0') {
				fprintf(stderr,
					"Error: Password may not start with '\\0'.\n");
				exit(EXIT_FAILURE);
			}
			strncpy(password, argv[i], MAX_PASS + 1);
		} else if (! strcmp(argv[i], "-s")) {
			safe_mode = true;
		} else {
			*(names[name_index++]) = argv[i];
		}
	}

	if (password[0] == '\0') {
		getPassword(&password);
	}

	if (safe_mode) {
		isSecure(pad_name);
		isSecure(infile_name);
		exists(outfile_name);
	}

	padCrypt(pad_name, infile_name, outfile_name, password);

	free(password);
	return 0;
}


