%include "boot.inc"                                             ; 加载boot.inc库
section loader vstart=LOADER_BASE_ADDR          ; loader在内存中的位置，MBR要把loader从硬盘读入后放到此处
LOADER_STACK_TOP equ LOADER_BASE_ADDR    ; 用于loader在保护模式下的栈

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

; 当前偏移loader.bin文件头0x200字节   （4个段描述符 + 预留的60个槽位）* 每个大小8字节 = 512 = 0x200字节
; loader.bin的加载地址是0x900，故total_mem_bytes内存中的地址是0xb00，将来内核中会引用此地址
total_mem_bytes dd 0     ; 定义了4字节的变量，用于存储获取到的内存容量，以字节为单位


; --------以下是 gdt 的指针，前 2 字节是 gdt 界限，后 4 字节是 gdt 起始地址------
gdt_ptr dw GDT_LIMIT                                  ; gdt界限
            dd GDT_BASE                                   ; gdt起始地址


; ---下面提前定义缓冲区，为的是存储BIOS 0x15中断0xe820子功能返回的ARDS结构-----
; ---每执行该中断一次便会得到一个ARDS结构的数据，按理说缓冲区的大小等于ARDS结构大小就行，但为了省事-----
; ---处理的思路是将所有ARDS都得到后再统一遍历，所以就申请个大一些的缓冲区，缓冲区地址是ards_buf--------
; ---一个ARDS结构是20字节，本机测试中返回6个，然后为了手工对齐下面标签处loader_start，使其文件内的偏移地址为0x300----
; ---这样做纯粹为了地址凑个整数而已，无其他意义-----
; ---人工对齐：total_mem_bytes4字节 + gdt_ptr6字节 + ards_buf244字节 + ards_nr2字节 = 256字节 = 0x100
ards_buf times 244 db 0    ; 缓冲区
ards_nr dw 0                     ; 用于记录ARDS结构体数量


loader_start:
;;;;;; --------------------  下面会用3种方法获取内存大小  -------------------- ;;;;;;
;;;;;; ---- 3种方法探测到的内存容量都同意跳转到mem_get_ok处后以字节形式写入到变量total_mem_bytes，都用edx来保存 ---- ;;;;;;

; ---------第1种，子功能号0xe820方法，int 0x15h eax=0000E820, edx=534D4150h("SMAP")获取内存布局---------------
; 需要提前准备好一块数据缓冲区用于存放返回的ARDS结构，上面已经备好，即ards_buf
; 此方法，es:di存放缓冲区地址，es已在mbr赋值，则下面只需为di赋值
; 每执行int 0x15，eax、ebx、ecx都会更新。
; eax的值有之前的子功能号变成SMAP的ASCII码，ebx为新的后续值，不用干涉，ecx为实际写入缓冲区的字节数
; eax、ecx每次调用要更新为正确的输入参数，所以放在循环中
; 接下来每得到一个ARDS则di加一个ARDS大小，20字节，同时ards_nr + 1
; 代码如下：
xor ebx,ebx                          ; 第一次调用时，ebx值要为0
mov edx,0x534d4150           ; edx只赋值一次，循环体中不会改变
mov di,ards_buf                   ; ards结构缓冲区
e820_mem_get_loop:          ; 循环获取每个ARDS内存范围描述结构
	mov eax,0x0000e820            ; 执行 int 0x15后， eax值变为0x534d4150，所以每次执行 int 前都要更新为子功能号
	mov ecx,20                          ; ARDS地址范围描述符结构大小是20字节
	int 0x15                               ; 通过15中断，开始获取内存
	jc e820_failed_so_try_e801    ; 若cf位为1则有错误发生，尝试0xe801子功能
	add di, cx                             ; 使di增加20字节指向缓冲区中新的ARDS结构位置
	inc word [ards_nr]                ; 记录ARDS数量
	cmp ebx, 0                           ; 若 ebx为0且cf 不为1，这说明ards全部返回
	jnz e820_mem_get_loop       ; 循环执行获取 

; -----下面是找出最大的内存，详细解释可以看原书籍教程------
mov cx, [ards_nr]
mov ebx, ards_buf          ; ARDS地址
xor edx, edx                   ; edx 为最大的内存容量，在此先清 0
find_max_mem_area:      ; 遍历每一个 ARDS 结构体，循环次数是 ARDS 的数量，无需判断type是否为1，最大的内存块一定是可被使用的
	mov eax, [ebx]          ; base_add_low
	add eax, [ebx+8]       ; length_low
	add ebx, 20               ; 指向缓冲区中下一个ARDS结构
	cmp edx, eax            ; 比较，冒泡排序找出最大edx寄存器始终是最大的内存容量
	jge next_ards            ; 小于等于跳转
	mov edx,eax             ; edx 为总内存大小
next_ards:
	loop find_max_mem_area
jmp mem_get_ok

; ---------第2种，子功能号0xe801方法，int 0x15h ax=E801h最大支持4G---------------
; 此方法详细解释见原书籍教程
; 返回后, ax和cx值一样，以1KB为单位，bx和dx值一样，以64KB为单位
; 在ax和cx寄存器中为低16MB，在bx和dx寄存器中为16MB到4GB
e820_failed_so_try_e801:
	mov ax,0xe801
	int 0x15
	jc e801_failed_so_try88      ; 若当前e801方法失败，就尝试0x88方法
	; 先算出低15MB的内存，ax和cx中是以1KB为单位的内存数量，将其转换为以byte为单位
	mov cx,0x400                     ; cx和ax值一样，cx用作乘数
	mul cx
	shl edx,16
	and eax,0x0000FFFF
	or edx,eax
	add edx, 0x100000         ; ax只是15MB，故要加1MB
	mov esi,edx                   ; 先把低15MB的内存容量存入esi寄存器备份
	; 再将16MB以上的内存转换为byte为单位，寄存器bx和dx中是以64KB为单位的内存数量
	xor eax,eax
	mov ax,bx
	mov ecx,0x10000     ; 0x10000十进制为64KB
	mul ecx                   ; 32位乘法，默认的被乘数是eax，积为64位，高32位存入edx，低32位存入eax
	add esi,eax
	; 由于此方法只能测出 4GB 以内的内存，故32 位eax足够了，edx肯定为0，只加eax便可
	mov edx,esi               ; edx 为总内存大小
	jmp mem_get_ok

; ---------第3种，子功能号0x88方法，int 0x15h ah=0x88 只能获取64MB之内---------------
; 详细见原书籍教程
e801_failed_so_try88:        ; int 15后，ax存入的是以KB为单位的内存容量
	mov ah, 0x88
	int 0x15
	jc error_hlt                     ; 出错，挂起
	and eax,0x0000FFFF

	; 16位乘法，被乘数是ax，积为32位。积的高16位在dx中，积的低16位在ax中
	mov cx, 0x400                ; 0x400等于1024，将ax中的内存容量换为以byte为单位
	mul cx
	shl edx,16                       ; 把dx移到高16位
	or edx,eax                       ; 把积的低16位组合到edx，为32位的积
	add edx,0x100000           ; 0x88子功能只会返回1MB以上的内存，故实际内存大小要加上1MB

mem_get_ok:
	mov [total_mem_bytes], edx     ; 将内存换为 byte 单位后存入 total_mem_bytes 处
error_hlt:		   ; 出错则挂起
   hlt

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

; 下面的跳转指令是为了刷新流水线，这将导致之前做的预测失效，从而起到了刷新的作用
jmp dword SELECTOR_CODE:p_mode_start

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