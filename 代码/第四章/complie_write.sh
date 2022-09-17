#!/bin/bash

# 编译mbr.S
nasm -I boot.inc -o mbr.bin mbr.S

# 将mbr.bin写入虚拟硬盘扇区0
dd if=mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc

# 编译loader.S
nasm -I boot.inc -o loader.bin loader.S

# 将loader.bin写入扇区2开始的4个扇区
dd if=loader.bin of=hd60M.img bs=512 count=4 seek=2 conv=notrunc