
voyboot.o: voyboot.asm
	mkdir -p .builds
	nasm -f elf64 voyboot.asm -o .builds/voyboot.o
	ld -shared .builds/voyboot.o -o voy
	sh ./blinkenlights.com -t -v ./voy

debug: voyboot.asm
	mkdir -p .builds
	nasm -f elf64 voyboot.asm -o voyboot.o
	ld -shared voyboot.o -o voy
	../gf/gf2 -d .

test: testcf.asm
	mkdir -p .builds
	nasm -f elf64 testcf.asm -o .builds/testcf.o
	ld -shared .builds/testcf.o -o .builds/testcf
	sh ./blinkenlights.com -t .builds/testcf
