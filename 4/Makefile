AS = /usr/bin/nasm
LD = /usr/bin/ld
CC = gcc

ASFLAGS = -g -f elf64
LDFLAGS = -static -z noexecstack

LIBS = -lgcc -lgcc_eh -lc -lm
OBJPATH = /usr/lib

SRCS = prog.s
OBJS = $(SRCS:.s=.o)

EXE = prog

all: $(EXE)

$(EXE): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(EXE) $(LIBS)

$(OBJS): $(SRCS)
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf $(OBJS) $(EXE)
