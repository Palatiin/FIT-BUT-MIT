# Project: FLP - Logical Project - Turing Machine
# Author: Matus Remen (xremen01@stud.fit.vutbr.cz)

.PHONY: pack clean test

FILE=turing.pl

all:
	export LC_ALL=en_US.UTF-8
	export LC_CTYPE=en_US.UTF-8
	export LANG=en_US.UTF-8
	swipl -q -g start -o flp23-log -c $(FILE)

test:
	./test.sh

clean:
	rm flp23-log

pack:
	zip flp-log-xremen01.zip Makefile $(FILE) README.md test.sh tests/*
