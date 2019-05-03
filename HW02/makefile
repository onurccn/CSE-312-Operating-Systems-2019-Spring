CFLAGS = -std=c++11
all: HW02

HW02: main.o gtuos.o 8080emu.o memory.o
	g++ main.o gtuos.o 8080emu.o memory.o -o HW02

main.o: main.cpp
	g++ $(CFLAGS) -c main.cpp

gtuos.o: gtuos.cpp
	g++ $(CFLAGS) -c gtuos.cpp

8080emu.o: 8080emu.cpp
	g++ $(CFLAGS) -c 8080emu.cpp

memory.o: memory.cpp
	g++ $(CFLAGS) -c memory.cpp

clean:
	rm *.o