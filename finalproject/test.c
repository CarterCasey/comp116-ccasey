#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[])
{
	if (argc != 2) {
		fprintf(stderr, "Usage: ./test <file-path>\n");
		exit(EXIT_FAILURE);
	}

	struct stat s;

	stat(argv[1], &s);

	printf("%o\n", s.st_mode);

	if (s.st_mode & 0002) {
		printf("File \"%s\" is writable by all users\n", argv[1]);
	}
	
	return 0;
}