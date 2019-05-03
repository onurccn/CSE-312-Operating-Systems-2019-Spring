#include <iostream>
#include <fstream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <cmath>
#include <string>
#include <time.h>

using namespace std;

uint64_t GTUOS::handleCall(CPU8080 & cpu){
	switch(cpu.state->a){
		case PRINT_B:
			cout << "PRINT_B" << endl;
			printRegisterBDecimal(cpu);
			break;
		case PRINT_MEM:
			cout << "PRINT_MEM" << endl;
			printRegisterBMemory(cpu);
			break;
		case READ_B:
			cout << "READ_B" << endl;
			readToRegisterBDecimal(cpu);
			break;
		case READ_MEM:
			cout << "READ_MEM" << endl;
			readToRegisterBCMemory(cpu);
			break;
		case PRINT_STR:
			cout << "PRINT_STR" << endl;
			return printString(cpu) * 10;
		case READ_STR:
			cout << "READ_STR" << endl;
			return readToRegisterBCString(cpu) * 10;
		case LOAD_EXEC:
			if (loadExecRaiseInterrupt) {
				printf("RESET LOAD_EXEC\n");
				loadExecRaiseInterrupt = 0;
				return 0;
			}
			cout << "LOAD_EXEC" << endl;
			loadExec(cpu);
			return 100;
		case SET_QUANTUM:
			cout << "SET_QUANTUM" << endl;
			cpu.setQuantum(cpu.state->b);
			return 7;
		case PROCESS_EXIT:
			if (exitProcessRaiseInterrupt) {
				printf("RESET PROCESS_EXIT\n");
				exitProcessRaiseInterrupt = 0;
				return 0;
			}
			cout << "PROCESS_EXIT" << endl;
			exitProcess(cpu);
			return 80;

		case RAND_INT:
			randInt(cpu);
			return 60;
		case WAIT:
			wait(cpu);
			return 200;
		case SIGNAL:
			signal(cpu);
			return 200;
		default:
			return 0; // No registered System call counts as 0 cycles.
	}

	return 10;
}
void GTUOS::printTable(CPU8080 & cpu){
	ProcessTableEntry * cursor = processTable;
	while(cursor != NULL) {
		printf("Next: %x, ID: %x, Counter: %d , Name: %s, BaseReg: %x\n", cursor->nextEntryAddress, cursor->processId, cursor->programCounter, cursor->processName, cursor->baseReg);
		cursor = cursor->nextEntry;
	}
}

void GTUOS::randInt(CPU8080 & cpu) {
	srand(time(NULL));
	cpu.state->b = rand() % 0xFF;
}

void GTUOS::wait(CPU8080 & cpu) {
	uint8_t mailboxID = cpu.state->b;
	uint8_t condVarAddr = cpu.state->c;	// 1 or 2 to identify which semaphore to point
	uint16_t mailboxAddress = mailboxBaseAddress + ((mailboxID - 1) * mailboxSize);
	if (cpu.memory->physicalAt(mailboxAddress + condVarAddr) > 0) {
		cpu.memory->physicalAt(mailboxAddress + condVarAddr)--;
	}
	else {
		// cause pc to revert back to current instruction and made context scheduling to happen.
		cpu.raiseInterrupt(0xef);
	}
}

void GTUOS::signal(CPU8080 & cpu) {	
	uint8_t mailboxID = cpu.state->b;
	uint8_t condVarAddr = cpu.state->c;	// 1 or 2 to identify which semaphore to point
	uint16_t mailboxAddress = mailboxBaseAddress + ((mailboxID - 1) * mailboxSize);
	cpu.memory->physicalAt(mailboxAddress + condVarAddr)++;
}

void GTUOS::exitProcess(CPU8080 & cpu){
	uint8_t currentProcess = cpu.memory->physicalAt(currentProcessLocation);
	ProcessTableEntry * currentProcessEntry, * cursor = processTable;
	uint16_t baseAddress;
	if (cursor->processId == currentProcess){
		baseAddress = processTableBaseAddress;
		currentProcessEntry = cursor;
		cursor = NULL;
	}
	else {
		while (cursor->nextEntry != NULL && cursor->nextEntry->processId != currentProcess) cursor = cursor->nextEntry;
		if (cursor->nextEntry->processId != currentProcess) return;
		baseAddress = cursor->nextEntryAddress;
		currentProcessEntry = cursor->nextEntry;
	}
	
	// Delete process data from memory
	uint16_t nextProcessAddress = (cpu.memory->physicalAt(baseAddress) << 8) + cpu.memory->physicalAt(baseAddress + 1);
	for (int i = baseAddress; i < currentProcessEntry->nextEntryAddress; i++) {
		cpu.memory->physicalAt(i) = 0;
	}

	// Delete current node
	if (cursor != NULL) {
		cursor->nextEntry = currentProcessEntry->nextEntry;
		cpu.memory->physicalAt(cursor->baseReg - 110) = currentProcessEntry->nextEntryAddress >> 8;
		cpu.memory->physicalAt(cursor->baseReg - 109) = currentProcessEntry->nextEntryAddress;
		cursor->nextEntryAddress = currentProcessEntry->nextEntryAddress;
	}
	else {
		processTable = currentProcessEntry->nextEntry;
		processTableBaseAddress = nextProcessAddress;
		cpu.memory->physicalAt(memoryBase) = nextProcessAddress >> 8;
		cpu.memory->physicalAt(memoryBase + 1) = nextProcessAddress;
	}
	uint16_t nextProcessLocation = cpu.memory->physicalAt(nextProcessAddress) == 0 ? memoryBase : nextProcessAddress;
	cpu.memory->physicalAt(nextProcessLocationMem + 1) = nextProcessLocation >> 8;
	cpu.memory->physicalAt(nextProcessLocationMem) = nextProcessLocation;
	//printf("%x - %x - %x - %x - %x\n", cpu.memory->physicalAt(nextProcessLocationMem), nextProcessLocation >> 8, nextProcessLocation, nextProcessAddress, baseAddress);
	free(currentProcessEntry);
	cpu.memory->physicalAt(processCount) -= 1;
	cpu.raiseInterrupt(0xef);
	exitProcessRaiseInterrupt = 0;
}

void GTUOS::loadExec(CPU8080 & cpu) {
	unsigned int index = getBCIndex(cpu);
	string filename = "";
	for(size_t i = index; cpu.memory->at(i) != 0; i++)
	{
		filename += cpu.memory->at(i);
	}

	uint16_t startAddress = (cpu.state->h << 8) + cpu.state->l;
	cpu.ReadFileIntoMemoryAt(filename.c_str(), startAddress);
	cpu.raiseInterrupt(0xef);
	loadExecRaiseInterrupt = 1;
	uint16_t base = startAddress - 110;
	ProcessTableEntry * cursor = processTable;
	if (processTable != NULL) {
		while (cursor->nextEntry != NULL) cursor = cursor->nextEntry;
		base = cursor->nextEntryAddress;
		cursor->nextEntry = (ProcessTableEntry *) malloc(sizeof(ProcessTableEntry));
		cursor = cursor->nextEntry;
	}
	else {
		processTable = cursor = (ProcessTableEntry *) malloc(sizeof(ProcessTableEntry));
	}

	cursor->nextEntryAddress = (cpu.memory->physicalAt(base) << 8) + cpu.memory->physicalAt(base + 1);
	cursor->processId = cpu.memory->physicalAt(base + 2);
	cursor->programCounter = (cpu.memory->physicalAt(base + 3) << 8) + cpu.memory->physicalAt(base + 4);
	int i;
	for (i = 0; cpu.memory->physicalAt(base + 5 + i) != '\0' && i < 100; i++){
		cursor->processName[i] = cpu.memory->physicalAt(base + 5 + i);
	}
	cursor->processName[(i < 99) ? i : 99] = '\0';
	cursor->baseReg = (cpu.memory->physicalAt(base + 105) << 8) + cpu.memory->physicalAt(base + 106);
	cursor->stackPointer = (cpu.memory->physicalAt(base + 107) << 8) + cpu.memory->physicalAt(base + 108);
	cursor->programState = cpu.memory->physicalAt(base + 109);
	cursor->nextEntry = NULL;
	
	cpu.memory->physicalAt(processCount) += 1;
}

void GTUOS::readToRegisterBDecimal(const CPU8080 & cpu){
	string line = readStringFromFile();

	int value = stoi(line);
	cpu.state->b = value;
}

void GTUOS::readToRegisterBCMemory(const CPU8080 & cpu){
	string line = readStringFromFile();
	
	int value = stoi(line);
	int index = getBCIndex(cpu);
	cpu.memory->at(index) = value;
}

unsigned int GTUOS::readToRegisterBCString(const CPU8080 & cpu){
	string line = readStringFromFile();

	int index = getBCIndex(cpu);
	for(int i = index, j = 0; j <= line.length(); i++, j++)
	{
		cpu.memory->at(i) = line[j];
	}

	return line.length();
}

void GTUOS::printRegisterBDecimal(const CPU8080 & cpu){
	int integer = cpu.state->b;
	string str = to_string(integer);
	printStringToFile(str);
}

void GTUOS::printRegisterBMemory(const CPU8080 & cpu){
	unsigned int index = getBCIndex(cpu);
	int value = cpu.memory->at(index);
	string str = to_string(value);
	printStringToFile(str);
}

void GTUOS::printStringToFile(const string str){
	ofstream file;
	file.open(outputFileName, ios_base::app|ios_base::ate);
	
	if (file.is_open()){
		file << str;
		file.close();
	}
	else {
		cerr << "Output file couldn't be opened." << endl;
	}
}

unsigned int GTUOS::printString(const CPU8080 & cpu){
	unsigned int index = getBCIndex(cpu);
	string str = "";
	for(size_t i = index; cpu.memory->at(i) != 0; i++)
	{
		str += cpu.memory->at(i);
	}
	
	printStringToFile(str);

	return str.length();
}

string GTUOS::readStringFromFile(){
	string line;
	
	if (!inFile.is_open()){
		inFile.open(inputFileName);
		// Empty file as we read input
		// ofstream temp;
		// temp.open("temp.txt");
		// string tempLine;
		// while(getline(inFile, tempLine)){
		// 	temp << tempLine << endl;
		// }
		// inFile.close();
		// temp.close();
		// remove(inputFileName.c_str());
		// rename("temp.txt", inputFileName.c_str());
	}
	inFile.seekg(0, inFile.beg);
	getline(inFile, line);

	return line;
}

int GTUOS::getBCIndex(const CPU8080 & cpu){
	return cpu.state->b * pow(2, 8) + cpu.state->c;
}
