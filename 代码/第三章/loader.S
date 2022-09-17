; loader 是要经过实模式到保护模式的过渡，并最终在保护模式下加载内核
; 本节只实现一个简单的 loader，本 loader 只在实模式下工作
%include "boot.inc"             ; 导入boot.inc文件，里面存放了宏
section loader vstart=LOADER_BASE_ADDR    ; 汇编伪指令，表示编译时，告诉编译器，把起始地址编译为 0x7c00

; 下面是把一些字符数据直接放入显存，屏幕最终会显示背景色绿色，前景色红色，并且跳动的字符串"1 MBR"
mov byte [gs:0x00],'2'
mov byte [gs:0x01],0xA4

mov byte [gs:0x02],' '
mov byte [gs:0x03],0xA4

mov byte [gs:0x04],'L'
mov byte [gs:0x05],0xA4

mov byte [gs:0x06],'O'
mov byte [gs:0x07],0xA4

mov byte [gs:0x08],'A'
mov byte [gs:0x09],0xA4

mov byte [gs:0x0a],'D'
mov byte [gs:0x0b],0xA4

mov byte [gs:0x0c],'E'
mov byte [gs:0x0d],0xA4

mov byte [gs:0x0e],'R'
mov byte [gs:0x0f],0xA4

jmp $