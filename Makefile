
voyboot.o: cf.asm
	mkdir -p .builds
	nasm -f elf64 cf.asm -o .builds/voyboot.o
	ld -shared .builds/voyboot.o -o voy
	sh ./blinkenlights.com -t -v ./voy

debug: cf.asm
	mkdir -p .builds
	nasm -f elf64 cf.asm -o .builds/voyboot.o
	ld -shared .builds/voyboot.o -o voy
	../gf/gf2 -d .

lib: libcf.asm
	mkdir -p .builds
	nasm -f elf64 libcf.asm -o .builds/libcf.o
	ld -shared .builds/libcf.o -o libcf.so

libdbg: libcf.so
	mkdir -p .builds
	gcc gdbframe.c -o .builds/gdbframe
	../gf/gf2 -d .
