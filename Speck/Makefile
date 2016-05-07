Speck: Speck.o
	ld -o Speck Speck.o
Speck.o: Speck.asm
	nasm -f elf64 -g -F dwarf Speck.asm -l Speck.lst
clean:
	rm -f Speck Speck.o Speck.lst
