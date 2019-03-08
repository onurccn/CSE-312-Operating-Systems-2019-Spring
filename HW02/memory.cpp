#include <iostream>
#include "memory.h"

Memory::Memory(uint64_t size) {
	mem = (uint8_t*) calloc(size, sizeof(uint8_t));
	baseRegister = 0;
	limitRegister = 0;
}

uint8_t & Memory::at(uint32_t ind) {
	return mem[ind + baseRegister];
}