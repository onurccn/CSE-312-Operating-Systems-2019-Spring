#ifndef H_GTUOS
#define H_GTUOS

#include "8080emuCPP.h"
#include <string>
#include <fstream>

enum SYSCALL{
	PRINT_B = 1,
	PRINT_MEM = 2,
	READ_B = 3,
	READ_MEM = 4,
	PRINT_STR = 5,
	READ_STR = 6
};

class GTUOS{
	public:
		uint64_t handleCall(const CPU8080 & cpu);
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

		int getBCIndex(const CPU8080 & cpu);
		void printStringToFile(const std::string str);
		std::string readStringFromFile();
};

#endif
