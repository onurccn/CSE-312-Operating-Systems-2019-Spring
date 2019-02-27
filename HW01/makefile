all: HW01

HW01: main.o gtuos.o 8080emu.o
	g++ main.o gtuos.o 8080emu.o -o HW01

main.o: main.cpp
	g++ -std=c++11 -c main.cpp

gtuos.o: gtuos.cpp
	g++ -std=c++11 -c gtuos.cpp

8080emu.o: 8080emu.cpp
	g++ -std=c++11 -c 8080emu.cpp

clean:
	rm *.o