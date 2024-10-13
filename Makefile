AS = nasm
ASFLAGS = -f elf64 -gdwarf

LD = ld

.PHONY: all clean

all: branchless-fizzbuzz

branchless-fizzbuzz: branchless-fizzbuzz.o
	$(LD) $^ -o $@

branchless-fizzbuzz.o: branchless-fizzbuzz.s
	$(AS) $(ASFLAGS) $^ -o $@

clean:
	rm -f branchless-fizzbuzz branchless-fizzbuzz.o
