#include <sys/types.h>
#include <sys/stat.h>
#if ! defined(__APPLE__)
	#include <shadow.h>
#endif
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[])
{
	if (argc < 3) exit(EXIT_FAILURE);
	printf("%s\n", crypt(argv[1], argv[2]));
	
	return 0;
}