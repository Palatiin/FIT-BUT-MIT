CXX=g++
CXXFLAGS=-std=c++17 -Wall -Wextra#-g -fsanitize=address -fsanitize=leak

.PHONY: pack clean test

PROG=kry

all: sha256.o
	$(CXX) $(CXXFLAGS) -o $(PROG) $(PROG).cpp sha256.o

test:
	make
	python3 test.py

clean:
	rm $(PROG) *.o

pack:
	zip 231876.zip $(PROG).cpp sha256.cpp sha256.hpp test.py Makefile README.md

