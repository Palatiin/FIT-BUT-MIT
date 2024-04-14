export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

.PHONY: pack

FILE=turing.pl

all:
	swipl -q -g start -o flp23-log -c $(FILE)

clean:
	rm flp23-log

pack:
	zip flp-log-xremen01.zip Makefile $(FILE) README.md
