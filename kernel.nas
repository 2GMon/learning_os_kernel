%include "init.inc"

[org 0x10000]
[bits 16]

start:
    cld
    mov     ax, cs
    mov     ds, ax
    xor     ax, ax
    mov     ss, ax

    xor     eax, eax
    lea     eax, [tss]                 ; EAXにtss1の物理アドレスを入れる
    add     eax, 0x10000
    mov     [descriptor4+2], ax
    shr     eax, 16
    mov     [descriptor4+4], al
    mov     [descriptor4+7], ah

    xor     eax, eax
    lea     eax, [printf]               ; EAXにprintf関数のアドレスを入れる
    add     eax, 0x10000
    mov     [descriptor7], ax
    shr     eax, 16
    mov     [descriptor7+6], al
    mov     [descriptor7+7], ah

    cli
    lgdt    [gdtr]

    mov     eax, cr0
    or      eax, 0x00000001
    mov     cr0, eax

    jmp     $+2
    nop
    nop

    jmp     dword SysCodeSelector:PM_Start

[bits 32]

PM_Start:
    mov     bx, SysDataSelector
    mov     ds, bx
    mov     es, bx
    mov     fs, bx
    mov     gs, bx
    mov     ss, bx

    lea     esp, [PM_Start]

    mov     ax, TSSSelector
    ltr     ax

    mov     [tss_esp0], esp             ; 特権レベル0のスタックをTSSに指定しておく
    lea     eax, [PM_Start-256]
    mov     [tss_esp], eax              ; 特権レベル3のスタックをTSSに指定しておく

    mov     ax, UserDataSelector        ; データセグメントをユーザモードに指定しておく
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    lea     esp, [PM_Start-256]

    push    dword UserDataSelector      ; SS
    push    esp                         ; ESP
    push    dword 0x200                 ; EFLAGS
    push    dword UserCodeSelector      ; CS
    lea     eax, [user_process]
    push    eax                         ; EIP
    iretd                               ; ユーザモードタスクにジャンプ

;;;;;;;;;;;;;;;
; Subroutines ;
;;;;;;;;;;;;;;;
printf:
    mov     ebp, esp
    push    es
    push    eax
    mov     ax, VideoSelector
    mov     es, ax
    mov     esi, [ebp+8]
    mov     edi, [ebp+12]

printf_loop:
    mov     al, byte [esi]
    mov     byte [es:edi], al
    inc     edi
    mov     byte [es:edi], 0x06
    inc     esi
    inc     edi
    or      al, al
    jz      printf_end
    jmp     printf_loop

printf_end:
    pop     eax
    pop     es
    ret

user_process:
    mov     edi, 80*2*7
    push    edi                         ; 引数をユーザモードスタックに保存する
    lea     eax, [msg_user_parameter1]
    push    eax
    call    0x38:0                      ; コールゲートを通じてカーネルルーチンを呼び出す
    jmp     $

;;;;;;;;;;;;;
; Data Area ;
;;;;;;;;;;;;;
msg_user_parameter1    db  "This is User Parameter1", 0

gdtr:
    dw      gdt_end - gdt - 1   ; GDTのlimit
    dd      gdt                 ; GDTのベースアドレス

gdt:
    dd      0, 0
    dd      0x0000FFFF, 0x00CF9A00
    dd      0x0000FFFF, 0x00CF9200
    dd      0x8000FFFF, 0x0040920B

descriptor4:
    dw      104
    dw      0
    db      0
    db      0x89
    db      0
    db      0

    dd      0x0000FFFF, 0x00FCFA00      ; ユーザーコードセグメント
    dd      0x0000FFFF, 0x00FCF200      ; ユーザーデータセグメント

descriptor7:
    dw      0
    dw      SysCodeSelector
    db      0x02
    db      0xEC
    db      0
    db      0

gdt_end:

tss:
    dw      0, 0                        ; 以前のタスクへback link

tss_esp0:
    dd      0                           ; ESP0
    dw      SysDataSelector, 0          ; SS0, 使用なし
    dd      0                           ; ESP1
    dw      0, 0                        ; SS1, 使用なし
    dd      0                           ; ESP2
    dw      0, 0                        ; SS2, 使用なし
    dd      0

tss_eip:
    dd      0, 0                        ; EIP, EFLAGS
    dd      0, 0, 0, 0

tss_esp:
    dd      0, 0, 0, 0                  ; ESP, EBP, ESI, EDI
    dw      0, 0                        ; ES, 使用なし
    dw      0, 0                        ; CS, 使用なし
    dw      UserDataSelector, 0         ; SS, 使用なし
    dw      0, 0                        ; DS, 使用なし
    dw      0, 0                        ; FS, 使用なし
    dw      0, 0                        ; GS, 使用なし
    dw      0, 0                        ; LDT, 使用なし
    dw      0, 0                        ; デバッグ用のTビット, IO許可ビットマップ

times   1024-($-$$) db 0
