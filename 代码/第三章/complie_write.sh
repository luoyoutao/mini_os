#!/bin/bash

# 这里有两个mbr，因此通过选项来确定把哪个mbr编译且写入虚拟硬盘
read -p "which one mbr.S you want complie and write to hard disk（please input 1 or 2）: " n
if test ${n} -eq 1
then
	nasm -o mbr.bin mbr1.S
else
	nasm -I boot.inc -o mbr.bin mbr2.S
	nasm -I boot.inc -o loader.bin loader.S
	dd if=loader.bin of=hd60M.img bs=512 count=1 seek=2 conv=notrunc  ; 将loader.bin写入虚拟硬盘的第2个扇区，mbr.bin在第0扇区
fi
# 下面将mbr.bin写入虚拟硬盘
dd if=mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc
