#define __PROGRAM_NAME "otpad"

#include <sys/types.h>
#include <sys/stat.h>
#include <termios.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pwd.h>

#define BUFF_FALLBACK 65536
#define RESPONSE_SIZE 8
#define ALL_WRITE 0002
#define MAX_PASS 32
#define MAX_NAME 32
#define ROOT_ID 0

void usage()
{
	fprintf(stderr, "Usage: ./otpad [-p <password>] <padfile> <infile> <outfile> \n");
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
	char* formatted = malloc(PATH_MAX + 7);

	sprintf(formatted, "stat(%s)", path);

	assertSys(stat(path, &s), formatted);
	
	uid_t uid = getuid();
	if (s.st_uid != uid && uid != 0) {
		getFileOwner(s.st_uid, &file_owner);
		fprintf(stderr, "Warning: %s\n is owned by %s.\n", path, file_owner);
		continuePrompt();
	}

	if (s.st_mode & ALL_WRITE) {
		fprintf(stderr, "Warning: %s is writable by all users\n", path);
		continuePrompt();
	}

	free(formatted);
}

void exists(char* path)
{
	char* formatted = malloc(PATH_MAX + 9);
	sprintf(formatted, "access(%s)", path);

	assertSys(access(path, F_OK), formatted);
	free(formatted);
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
	assertSys(fgets(*password_p, MAX_PASS + 1, stdin) == NULL, "fgets");
	toggleEcho(stdin);
	printf("\n");

	pass_len = strlen(*password_p);
	if ((*password_p)[pass_len - 1] != '\n') {
		fprintf(stderr,
				"Password is too long. It may be at most %d.\n", MAX_PASS);
	}
}

int main(int argc, char* argv[])
{
	char* password = malloc(MAX_PASS + 1);
	char* pad_name = NULL;
	char* infile_name = NULL;
	char* outfile_name = NULL;
	int   start_index = 1;

	if (argc > 5 || argc < 4) {
		usage();
	}

	for (int i = 2; i < argc - 1; i++) {
		if (! strcmp(argv[i], "-p")) {
			usage();
		}
	}

	if (! strcmp(argv[1], "-p")) {
		free(password);
		password = argv[2];
		start_index = 3;
	} else {
		getPassword(&password);
	}

	isSecure(pad_name = argv[start_index]);
	isSecure(infile_name = argv[start_index + 1]);
	exists(outfile_name = argv[start_index + 2]);

	return 0;
}


