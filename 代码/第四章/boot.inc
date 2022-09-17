LOADER_BASE_ADDR        equ  0x900        ; 定义loader在内存中的位置，MBR要把loader从硬盘读入后放到此处
LOADER_START_SECTOR   equ  0x2            ; 定义loader在硬盘上的逻辑扇区地址，即LBA地址

; -----------------------  gdt 描述属性 --------------------------
DESC_G_4K                  equ   1_00000000000000000000000b  ; 段描述符G位为1，表示段界限为4k的粒度
DESC_D_32                  equ   1_0000000000000000000000b    ; 段描述符D/B位为1，表示有效地址及操作数为32位
DESC_L                        equ   0_000000000000000000000b      ; 段描述符L位为0，表示为32位代码段
DESC_AVL                    equ   0_00000000000000000000b       ; 段描述符AVL位为0，无实际意义，留给操作系统用
DESC_LIMIT_CODE2     equ  1111_0000000000000000b          ; 段描述符代码段段界限的第 2 部分为1111b，它与段界限的第 1 部分将组成 20 个二进制 1，即总共的段界限将是 0xFFFFF
DESC_LIMIT_DATA2     equ   DESC_LIMIT_CODE2                  ; 段描述符数据段段界限同代码段段界限
DESC_LIMIT_VIDEO2    equ   0000_000000000000000b           ; 段描述符显存段段界限
DESC_P                        equ  1_000000000000000b                 ; 段描述符P位为1，表示段存在

; -------下面是段描述符的DPL位，表示不同的特权级-----
DESC_DPL_0    equ    00_0000000000000b
DESC_DPL_1    equ    01_0000000000000b
DESC_DPL_2    equ    10_0000000000000b
DESC_DPL_3    equ    11_0000000000000b

DESC_S_CODE   equ   1_000000000000b      ; 段描述符的S位为1，表示只是普通的内存段，不是系统段
DESC_S_DATA   equ    DESC_S_CODE          ; 段描述符的S位为1，表示只是普通的内存段，不是系统段
DESC_S_sys       equ    0_000000000000b     ; 段描述符的S位为0，表示是系统段

; ----------------TYPE位（x、e、w、a位）------------------------
DESC_TYPE_CODE    equ    1000_00000000b     ; 段描述符的TYPE位为1000b，表示代码段是可执行的，非一致性，不可读，已访问位a清0
DESC_TYPE_DATA    equ    0010_00000000b     ; 段描述符的TYPE位为0010b，表示数据段是不可执行的，向上扩展的，可写，已访问位a清0

; -------------------------------------代码段、数据段、显存段的段描述符的最高4字节--------------------------------------
DESC_CODE_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
DESC_DATA_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;-------------- 选择子属性 RPL请求特权级 以及 TI位---------------
RPL0     equ    00b
RPL1     equ    01b
RPL2     equ    10b
RPL3     equ    11b
TI_GDT   equ   000b
TI_LDT    equ   100b