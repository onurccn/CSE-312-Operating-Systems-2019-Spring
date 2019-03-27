#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <time.h>
	// This is just a sample main function, you should rewrite this file to handle problems 
	// with new multitasking and virtual memory additions.
int main (int argc, char**argv)
{
	if (argc != 3){
		std::cerr << "Usage: prog exeFile debugOption\n";
		exit(1); 
	}
	int DEBUG = atoi(argv[2]);

	Memory mem(0x10000);
	CPU8080 theCPU(&mem);
	GTUOS	theOS;

	theCPU.ReadFileIntoMemoryAt(argv[1], 0x0000);
	srand (time(NULL));
	mem.physicalAt(0x3A) = rand() % 3;
	do	
	{
		theCPU.Emulate8080p(DEBUG);
		if(theCPU.isSystemCall() && theCPU.interrupt != 1)
			theOS.handleCall(theCPU);
				
	}	while (!theCPU.isHalted())
;
	return 0;
}

