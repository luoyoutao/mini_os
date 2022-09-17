%include "boot.inc"                                             ; 加载boot.inc库
section loader vstart=LOADER_BASE_ADDR          ; loader在内存中的位置，MBR要把loader从硬盘读入后放到此处
LOADER_STACK_TOP equ LOADER_BASE_ADDR    ; 用于loader在保护模式下的栈
jmp loader_start                                                   ; 

; ------到下个虚线处之间都是构建gdt及其内部的描述符，这里构建了三个有用的段描述符，第一个是没用的，所以直接定义为全0----------------
GDT_BASE: 
dd 0x00000000    ; 第一个段描述符的低4字节
dd 0x00000000    ; 第一个段描述符的高4字节

CODE_DESC: dd 0x0000FFFF    ; 代码段描述符的低4字节
dd DESC_CODE_HIGH4            ; 代码段描述符的高4字节，用的boot.inc中定义的符号

DATA_STACK_DESC: dd 0x0000FFFF    ; 数据段和栈段描述符的低4字节
dd DESC_DATA_HIGH4                        ; 数据段和栈段描述符的高4字节，用的boot.inc中定义的符号。这里栈段描述同数据段描述符原因见教程

VIDEO_DESC: dd 0x80000007             ; 显存段描述符的低4字节，limit=(0xbffff-0xb8000)/4k=0x7，详细解释见后面
dd DESC_VIDEO_HIGH4                     ; 显存段描述符的高4字节，用boot.inc中定义的符号，此时DPL为0
; ------------------------------------------------------------------

GDT_SIZE equ $ - GDT_BASE             ; 通过地址差来获取GDT的大小
GDT_LIMIT equ GDT_SIZE - 1            ; GDT大小减一得到了段界限
times 60 dq 0   ; dp用来定义8字节数，time用来重复后面的表达式。此处为将来添加中断描述符表IDT和任务状态段TSS描述符，预留60个描述符的空位
SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0    ; 代码段选择子，相当于(CODE_DESC - GDT_BASE) / 8 + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0     ; 数据/栈段选择子，相当于(DATA_STACK_DESC - CODE_DESC) / 8 + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0   ; 代码段选择子，相当于(VIDEO_DESC - DATA_STACK_DESC) / 8 + TI_GDT + RPL0

; --------以下是 gdt 的指针，前 2 字节是 gdt 界限，后 4 字节是 gdt 起始地址------
gdt_ptr dw GDT_LIMIT                      ; gdt界限
dd GDT_BASE                                   ; gdt起始地址
loadermsg db '2 loader in real.'         ; 定义字符串，用来显示即将进入保护模式，当然是在实模式下打印的，用的还是BIOS中断


loader_start:
; --------- 下面是通过BIOS中断打印字符------------
mov sp, LOADER_BASE_ADDR
mov bp, loadermsg                  ; ES:BP = 字符串地址
mov cx, 17                               ; cx = 字符串长度
mov ax, 0x1301                        ; ah = 13, al = 01h，13子功能号，显示方式为1
mov bx, 0x001f                        ; 页号为 0(BH = 0) 蓝底粉红字(BL = 1fh)
mov dx, 0x1800                        ; 行数为0x18，列数dl为0x00
int 0x10                                   ; 10h号中断

; ------------ 下面准备进入保护模式 -----其步骤  1、打开A20地址线 2、加载gdt 3、将cr0的pe位 置1-----------

; ----1、打开A20-----
in al,0x92
or al,0000_0010B
out 0x92,al
; ----2、加载gdt-----
lgdt [gdt_ptr]
; ----3、cr0 第0位 置1----
mov eax, cr0
or eax, 0x00000001
mov cr0, eax

jmp dword SELECTOR_CODE:p_mode_start      ; 刷新流水线，这与处理器微架构的流水线有关

[bits 32]                          ; 后面的代码会按照32位机器码编译
p_mode_start:
; ----下面是用不同选择子初始化各段寄存器------
mov ax, SELECTOR_DATA
mov ds, ax
mov es, ax
mov ss, ax
mov esp,LOADER_STACK_TOP
mov ax, SELECTOR_VIDEO    
mov gs, ax

mov byte [gs:160], 'P'    ; 显示字符P

jmp $