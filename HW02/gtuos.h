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
		struct ProcessTableEntry {
			uint16_t nextEntryAddress;
			uint8_t processId;
			uint16_t programCounter;
			char processName[100];
			uint16_t baseReg;
			uint16_t stackPointer;
			uint8_t programState;
			ProcessTableEntry * nextEntry;
		};
		uint64_t handleCall(CPU8080 & cpu);
		int loadExecRaiseInterrupt = 0;
		int exitProcessRaiseInterrupt = 0;
		uint16_t memoryBase = 0x400;
		uint16_t processTableBaseAddress = memoryBase + 0x400;
		uint16_t currentProcessLocation = 0x33;
		uint16_t processCount = 0x37;
		uint16_t nextProcessLocationMem = 0x38;
	private:
		std::string outputFileName = "output.txt";
		std::string inputFileName = "input.txt";
		std::ifstream inFile;
		ProcessTableEntry * processTable = NULL;
		unsigned int printString(const CPU8080 & cpu);
		void printRegisterBDecimal(const CPU8080 & cpu);
		void printRegisterBMemory(const CPU8080 & cpu);
		void readToRegisterBDecimal(const CPU8080 & cpu);
		void readToRegisterBCMemory(const CPU8080 & cpu);
		unsigned int readToRegisterBCString(const CPU8080 & cpu);
		void loadExec(CPU8080 & cpu);
		void exitProcess(CPU8080 & cpu);
		void printTable(CPU8080 & cpu);

		int getBCIndex(const CPU8080 & cpu);
		void printStringToFile(const std::string str);
		std::string readStringFromFile();
};

#endif
