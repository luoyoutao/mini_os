#!/bin/bash

# complie mbr.S to mbr.bin
nasm -o mbr.bin mbr.S

# write mbr.bin to disk
dd if=mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc
