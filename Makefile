CPP = cpp
# CPPFLAGS = -isystem /usr/include/asm/

AS = nasm
ASFLAGS = -f elf64 -gdwarf

LD = ld

.PHONY: all

all: branchless-fizzbuzz

branchless-fizzbuzz: branchless-fizzbuzz.o
	$(LD) $^ -o $@

branchless-fizzbuzz.o: branchless-fizzbuzz.s
	$(AS) $(ASFLAGS) $^ -o $@

branchless-fizzbuzz.s: branchless-fizzbuzz.S
	$(CPP) $(CPPFLAGS) $^ > $@

clean:
	rm -f branchless-fizzbuzz branchless-fizzbuzz.o branchless-fizzbuzz.s
