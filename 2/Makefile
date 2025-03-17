AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64
LDFLAGS = -g -static

LTOG=0
ifeq ($(LTOG), 1)
    SRCS = $(PROJ_SRC)prog.s
else
    SRCS = $(PROJ_SRC)progr.s
endif

OBJS = $(SRCS:.s=.o)

EXE = prog

all: $(SRCS) $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@

.s.o:
	$(AS) $(ASFLAGS) $< -o $@
