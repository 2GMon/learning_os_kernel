%include "init.inc"

[org 0]
    jmp     07C0h:start

start:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax

reset:                          ; FDDをリセットする
    mov     ax, 0
    mov     dl, 0               ; Drive=0 (A:)
    int     13h
    jc      reset               ; エラーならやり直し

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
    mov     al, 2               ; これから2セクタ読む
    mov     ch, 0               ; 0番目のCylinder
    mov     cl, 2               ; 2番目のセクタから読み込み始める予定
    mov     dh, 0               ; Head=0
    mov     dl, 0               ; Drive=0 A:ドライブ
    int     13h                 ; Read!

    jc      read                ; エラーが出ると、やり直し

    mov     dx, 0x3F2           ; FDDの
    xor     al, al              ; モーターの電源を切る
    out     dx, al

    cli

    mov     al, 0x11            ; PICの初期化
    out     0x20, al            ; マスターPIC
    dw      0x00eb, 0x00eb      ; jmp $+2, jmp $+2
    out     0xA0, al            ; スレーブPIC
    dw      0x00eb, 0x00eb

    mov     al, 0x20            ; マスターPIC割り込みスタート地点
    out     0x21, al
    dw      0x00eb, 0x00eb
    mov     al, 0x28            ; スレーブPIC割り込みスタート地点
    out     0xA1, al
    dw      0x00eb, 0x00eb

    mov     al, 0x04            ; マスターPICのIRQ2番に
    out     0x21, al            ; スレーブPICがつながっている
    dw      0x00eb, 0x00eb
    mov     al, 0x02            ; スレーブPICがマスターPICの
    out     0xA1, al            ; IRQ2番につながっている
    dw      0x00eb, 0x00eb

    mov     al, 0x01            ; 8086モードを使う
    out     0x21, al
    dw      0x00eb, 0x00eb
    out     0xA1, al
    dw      0x00eb, 0x00eb

    mov     al, 0xFF            ; スレーブPICすべての割り込みを
    out     0xA1, al            ; 防いでおく
    dw      0x00eb, 0x00eb
    mov     al, 0xFB            ; マスターPICのIRQ2番を除いた
    out     0x21, al            ; 全ての割り込みを防いでおく

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
