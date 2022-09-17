%include "boot.inc"    ; nasm的预处理指令，意思把boot.inc文件包含进来，里面主要是编写的一些宏

; ------------ 以下到虚线截止，和mbr1.S没有变化。都是清屏然后直接把数据放入显存打印字符--------------
SECTION MBR vstart=0x7c00
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov fs,ax
mov sp,0x7c00
mov ax,0xb800
mov gs,ax

mov ax, 0600h
mov bx, 0700h
mov cx, 0
mov dx, 184fh
int 10h

mov byte [gs:0x00],'1'
mov byte [gs:0x01],0xA4

mov byte [gs:0x02],' '
mov byte [gs:0x03],0xA4

mov byte [gs:0x04],'M'
mov byte [gs:0x05],0xA4

mov byte [gs:0x06],'B'
mov byte [gs:0x07],0xA4

mov byte [gs:0x08],'R'
mov byte [gs:0x09],0xA4
; ----------------------到此处和mbr1.S没有变化--------------------------------

; ----------------------读取硬盘操作，先初始一些参数，然后调用函数----------
mov eax,LOADER_START_SECTOR    ; 待读入的扇区起始地址lba  0x2
mov bx,LOADER_BASE_ADDR           ; 读来后放入的内存地址 0x900
mov cx,4                                          ; 待读入的扇区数
call rd_disk_m_16                             ; 调用读扇区的函数

jmp LOADER_BASE_ADDR ; 读完后跳到内核加载器的位置，MBR到此结束使命，顺利完成第二棒的交接（第一棒是BIOS给MBR）

rd_disk_m_16:               ; 函数功能，读n扇区

mov esi,eax                  ; 扇区号
mov di,cx                     ; 读入的扇区数
; ----- 第1步，设置要读取的扇区数 -----
mov dx,0x1f2
mov al,cl
out dx,al                      ; 读取的扇区数送到0x1f2端口
; ----- 第2步，将LBA地址存入0x1f3~0x1f6 -----
mov eax,esi
; LBA 地址 7～ 0 位写入端口 0x1f3
mov dx,0x1f3
out dx,al
; LBA 地址 15～ 8 位写入端口 0x1f4
mov cl,8
shr eax,cl
mov dx,0x1f4
out dx,al
; LBA 地址 23～ 16 位写入端口 0x1f5
shr eax,cl       ; 逻辑右移8位
mov dx,0x1f5
out dx,al

shr eax,cl      ; 逻辑右移8位
and al,0x0f   ; lba第24 ~ 27位
or al,0xe0     ; 设置7~4位为1110，表示lba模式
mov dx,0x1f6
out dx,al
; ----- 第3步，向 0x1f7 端口写入读命令 0x20 -----
mov dx,0x1f7
mov al,0x20
out dx,al
; ----- 第 4 步，检测硬盘状态 -----
not_ready:
nop
in al,dx            ; 将status寄存器的值读入到al寄存器
and al,0x88      ; 第 4 位为 1 表示硬盘控制器已准备好数据传输
cmp al,0x08     ; 第 7 位为 1 表示硬盘忙
jnz not_ready   ; 若未准备好，继续等
; ----- 第 5 步，从 0x1f0 端口读数据 -----
mov ax, di       ; di 为要读取的扇区数，一个扇区有 512 字节，每次读入一个字
mov dx, 256
mul dx            ; ax * dx，即 1 * 256。共需 di*512/2 次，所以 di*256
mov cx, ax      ; 此处的最终结果全放在了ax，所以ax赋值给循环计数器cx

mov dx, 0x1f0
go_on_read:
in ax,dx
mov [bx],ax               ; 将进来的数据循环存入bx所在内存
add bx,2                   ; 每读2字节，地址+2
loop go_on_read       ; 循环读取
ret

times 510-($-$$) db 0
db 0x55,0xaa