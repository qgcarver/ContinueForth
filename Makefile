
voyboot.o: cf.asm
	mkdir -p .builds
	nasm -f elf64 cf.asm -o .builds/voyboot.o
	ld -shared .builds/voyboot.o -o voy
	sh ./blinkenlights.com -t -v ./voy

debug: cf.asm
	mkdir -p .builds
	nasm -f elf64 cf.asm -o voyboot.o
	ld -shared voyboot.o -o voy
	../gf/gf2 -d .
