#ifndef H_GTUOS
#define H_GTUOS

#include "8080emuCPP.h"
#include <string>
#include <fstream>

enum SYSCALL{
	PRINT_B = 4,
	PRINT_MEM = 3,
	READ_B = 7,
	READ_MEM = 2,
	PRINT_STR = 1,
	READ_STR = 8,
	LOAD_EXEC = 5,
	SET_QUANTUM = 6,
	PROCESS_EXIT = 9
};

class GTUOS{
	public:
		uint64_t handleCall(CPU8080 & cpu);
		int loadExecRaiseInterrupt = 0;
	private:
		std::string outputFileName = "output.txt";
		std::string inputFileName = "input.txt";
		std::ifstream inFile;
		unsigned int printString(const CPU8080 & cpu);
		void printRegisterBDecimal(const CPU8080 & cpu);
		void printRegisterBMemory(const CPU8080 & cpu);
		void readToRegisterBDecimal(const CPU8080 & cpu);
		void readToRegisterBCMemory(const CPU8080 & cpu);
		unsigned int readToRegisterBCString(const CPU8080 & cpu);
		void loadExec(CPU8080 & cpu);

		int getBCIndex(const CPU8080 & cpu);
		void printStringToFile(const std::string str);
		std::string readStringFromFile();
};

#endif
