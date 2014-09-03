[org 0]
[bits 16]

start:
    mov     ax, cs              ; CSには0x1000が入っている
    mov     ds, ax
    mov     ax, ax
    mov     ss, ax

    cli

    lgdt    [gdtr]

    mov     eax, cr0
    or      eax, 0x00000001
    mov     cr0, eax
    jmp     $ + 2
    nop
    nop

    db      0x66
    db      0x67
    db      0xEA
    dd      PM_Start
    dw      SysCodeSelector

;;;;;;;;;;;;;;;;;;;;;;;;;;
; ここからProtected Mode ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 32]

PM_Start:
    mov     bx, SysDataSelector
    mov     ds, bx
    mov     es, bx
    mov     fs, bx
    mov     gs, bx
    mov     ss, bx

    xor     eax, eax
    mov     ax, VideoSelector
    mov     es, ax
    mov     edi, 80*2*10+2*10
    lea     esi, [ds:msgPMode]
    call    printf

    jmp     $

;;;;;;;;;;;;;;;;
; Sub Routines ;
;;;;;;;;;;;;;;;;
printf:
    push eax

printf_loop:
    or      al, al
    jz      printf_end
    mov     al, byte [esi]
    mov     byte [es:edi], al
    inc     edi
    mov     byte [es:edi], 0x06
    inc     esi
    inc     edi
    jmp     printf_loop

printf_end:
    pop eax
    ret

msgPMode    db  "We are in Protected Mode", 0

;;;;;;;;;;;;;
; GDT Table ;
;;;;;;;;;;;;;
gdtr:
    dw      gdt_end - gdt - 1       ; GDTのlimit
    dd      gdt + 0x10000           ; GDTのベースアドレス

gdt:
    dw      0                       ; limit 0〜15ビット
    dw      0                       ; ベースアドレスの下位2バイト
    db      0                       ; ベースアドレスの16〜23ビット
    db      0                       ; Type
    db      0                       ; limit 16〜19ビット、フラグ
    db      0                       ; ベースアドレスの31〜24ビット

; コードセグメント・ディスクリプタ
SysCodeSelector equ     0x08
    dw      0xFFFF                  ; limit:0xFFFF
    dw      0x0000                  ; base 0〜15ビット
    db      0x01                    ; base 16〜32ビット
    db      0x9A                    ; P:1, DPL:0, Code, non-conforming, readable
    db      0xCF                    ; G:1, D:1, limit 16〜19ビット:0xF
    db      0x00                    ; base 24〜32ビット

; データセグメント・ディスクリプタ
SysDataSelector equ     0x10
    dw      0xFFFF                  ; limit 0xFFFF
    dw      0x0000                  ; base 0〜15ビット
    db      0x01                    ; base 16〜32ビット
    db      0x92                    ; P:1, DPL:0, data, expand-up, writable
    db      0xCF                    ; G:1, D:1, limit 16〜19ビット:0xF
    db      0x00                    ; base 24〜32ビット

; ビデオセグメント・ディスクリプタ
VideoSelector   equ     0x18
    dw      0xFFFF                  ; limit 0xFFFF
    dw      0x8000                  ; base 0〜15ビット
    db      0x0B                    ; base 16〜23ビット
    db      0x92                    ; P:1, DPL:0, data, expand-up, writable
    db      0x40                    ; G:0, D:1, limit 16〜19ビット:0
    db      0x00                    ; base 24〜32ビット

gdt_end:
