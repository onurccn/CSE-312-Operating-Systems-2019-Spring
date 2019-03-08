#ifndef H_MEMORY
#define H_MEMORY

#include <cstdlib>
#include "memoryBase.h"

// This is just a simple memory with no virtual addresses.
// You will write your own memory with base and limit registers.

class Memory: public MemoryBase {
public:
	Memory(uint64_t size);
	~Memory() { free(mem);}
	virtual uint8_t & at(uint32_t ind);
	virtual uint8_t & physicalAt(uint32_t ind) { return mem[ind];}
	uint16_t getBaseRegister() const { return baseRegister;}
	uint16_t getLimitRegister() const { return limitRegister;}
	void setBaseRegister(uint16_t base) { this->baseRegister = base;}
	void setLimitRegister(uint16_t limit) {this->limitRegister = limit;}

private:
	uint8_t * mem;
	uint16_t baseRegister;
	uint16_t limitRegister;
};

#endif


