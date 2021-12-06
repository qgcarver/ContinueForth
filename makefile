

cf.o: continueforth.S
	nasm -f elf64 continueforth.S -o cf.o
	ld -shared cf.o -o libcf.so
