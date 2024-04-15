CXX=g++
CXXFLAGS=-std=c++17 -Wall -Wextra -fsanitize=address -fsanitize=leak

.PHONY: pack clean

PROG=kry

all:
	$(CXX) $(CXXFLAGS) -c $(PROG).cpp -o $(PROG)

clean:
	rm $(PROG)

pack:
	zip 231876.zip $(PROG).cpp Makefile README.md

