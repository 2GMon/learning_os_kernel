%include "init.inc"

[org 0]
    jmp     07C0h:start

start:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax

    mov     ax, 0xB800
    mov     es, ax
    mov     di, 0
    mov     ax, word [msgBack]
    mov     cx, 0x7FF

paint:
    mov     word [es:di], ax
    add     di, 2
    dec     cx
    jnz     paint
read:
    mov     ax, 0x1000          ; ES:BX=1000:0000
    mov     es, ax
    mov     bx, 0
    mov     ah, 2               ; ディスクにあるデータをes:bxのアドレスに
    mov     al, 1               ; 1セクタを読み込む
    mov     ch, 0               ; 0番目のCylinder
    mov     cl, 2               ; 2番目のセクタから読み込み始める
    mov     dh, 0               ; Head=0
    mov     dl, 0               ; Drive=0 A:ドライブ
    int     0x13                ; Read!

    jc      read                ; エラーになれば、やり直し

    mov     dx, 0x3F2           ; FDDの
    xor     al, al              ; モーターの電源を切る
    out     dx, al

    cli
    mov     al, 0xFF            ; PICですべての割り込みを
    out     0xA1, al            ; 防いで機能しなくする

    lgdt    [gdtr]

    mov     eax, cr0
    or      eax, 0x00000001
    mov     cr0, eax
    jmp     $+2
    nop
    nop

    mov     bx, SysDataSelector
    mov     ds, bx
    mov     es, bx
    mov     fs, bx
    mov     gs, bx
    mov     ss, bx

    jmp     dword SysCodeSelector:0x10000

    msgBack db '.', 0x67

gdtr:
    dw      gdt_end - gdt - 1   ; GDTのlimit
    dd      gdt+0x7C00          ; GDTのベースアドレス
gdt:
    dd      0, 0
    dd      0x0000FFFF, 0x00CF9A00
    dd      0x0000FFFF, 0x00CF9200
    dd      0x8000FFFF, 0x0040920B
gdt_end:
times   510-($-$$)  db 0
        dw          0AA55h
