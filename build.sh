#!/bin/sh

if [ -f "continueforth.S" ]; then
    nasm -f elf64 continueforth.S -o cf.o
    ld -shared cf.o -o libcf.so
else
    echo "continueforth.S does not exist."
fi
