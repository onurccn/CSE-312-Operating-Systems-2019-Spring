#include <iostream>
#include <fstream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include <cmath>
#include <string>

using namespace std;

uint64_t GTUOS::handleCall(const CPU8080 & cpu){
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
		default:
			return 0; // No registered System call counts as 0 cycles.
	}

	return 10;
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
	
	getline(inFile, line);

	return line;
}

int GTUOS::getBCIndex(const CPU8080 & cpu){
	return cpu.state->b * pow(2, 8) + cpu.state->c;
}
