CXX=g++
CXXFLAGS=-std=c++17 -Wall -Wextra#-g -fsanitize=address -fsanitize=leak

.PHONY: pack clean

PROG=kry

all: sha256.o
	$(CXX) $(CXXFLAGS) -o $(PROG) $(PROG).cpp sha256.o

clean:
	rm $(PROG) *.o

pack:
	zip 231876.zip $(PROG).cpp Makefile README.md

