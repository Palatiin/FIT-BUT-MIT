CXX=mpic++
CXXFLAGS=--prefix /usr/local/share/OpenMPI

.PHONY: clean pack numbers run


all:
	$(CXX) $(CXXFLAGS) pms.cpp -o pms

numbers-%:
	dd if=/dev/random bs=1 count=$* of=numbers 2>/dev/null

run-%:
	./run $*

clean:
	rm pms numbers
