CC=gcc
ASM=nasm
CFLAGS?=-O0 -Wall -fno-stack-protector -z noexecstack
ASMFLAGS=-f elf64

all: prog

prog: main.o prog.o
	$(CC) -no-pie -z noexecstack -o $@ $^

main.o: main.c
	$(CC) $(CFLAGS) -c $<

prog.o: prog.s
	$(ASM) $(ASMFLAGS) $<

clean:
	rm -f *.o prog