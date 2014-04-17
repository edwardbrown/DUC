# Copyright (C) 2004 Edward Brown <ed@lexingrad.net>
#
# Top Makefile for duc
#
# Makefile 0.1 2004 

SHELL = /bin/sh

duc: duc.o
	gcc -m32 duc.o -o duc

duc.o: duc.asm
	nasm -f elf32 -i inc/  duc.asm

clean:
	rm -f *.o
	rm -f duc

install:
	cp -p duc /usr/local/bin/

.PHONY: clean install




