;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enable A20. This is at the very best an annoying procedure.
; A20 code ported from SYSLINUX 1.52-1.63 by H. Peter Anvin.
; AMD Elan bug fix by Robert Schwebel.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; CPUがAMD ELANである場合
;
; 飛ばした
;

A20_TEST_LOOPS      equ 32      ; waitするたびに繰り返す回数
A20_ENABLE_LOOPS    equ 255     ; テストするloopの合計
A20_TEST_ADDR       equ 4*0x80

a20_try_loop:

; まず、コンピュータにA20がないか調べる
a20_none:
call    a20_test
jnz     a20_done

; 次に BIOS (INT 0x15, AX=0x2401)をテストしてみる
a20_bios:
mov     ax, 0x2401
pushfd                          ; FLAGをちょっと深く疑う
int     0x15
popfd

call    a20_test
jnz     a20_done

; キーボードコントローラを通じてA20をONにしてみる
a20_kbc:
call    empty_8042

call    a20_test                ; BIOS側で施されている場合
jnz     a20_done                ; delayされた反応

mov     al, 0xD1                ; commandをライトする
out     0x64, al
call    empty_8042

mov     al, 0xDF                ; A20 on
out     0x60, al
call    empty_8042

; A20が本当にONになるまで待つ。これがあるシステムでは
; 相当長い時間かかる可能性がある
; Toshiba Tecrasはこういう問題を持っていると言われる
a20_kbc_wait:
xor     cx, cx
a20_kbc_wait_loop:
call    a20_test
jnz     a20_done
loop    a20_kbc_wait_loop

; 最後の試み： "制御ポート A"
a20_fast:
in      al, 0x92                ; 制御ポート A
or      al, 0x02                ; "fast A20" バージョンは
and     al, 0xFE                ; 急にRESETされない
out     0x92, al

; 制御ポートAに効果が出るのを待つ
a20_fast_wait:
xor     cx, cx
a20_fast_wait_loop:
call    a20_test
jnz     a20_done
loop    a20_fast_wait_loop

; A20がまだ反応を見せない。繰り返してみる
dec     byte [a20_tries]
jnz     a20_try_loop

a20_die:
hlt
jmp     a20_die

a20_tries:
db      A20_ENABLE_LOOPS

; ここまでくると、A20がONになったとしていい。
a20_done:
ret

a20_test:
push    cx
push    ax
xor     cx, cx
mov     fs, cx                  ; Low memory
dec     cx
mov     gs, cx                  ; High memory area
mov     cx, A20_TEST_LOOPS
mov     ax, word [fs:A20_TEST_ADDR]
push    ax
a20_test_wait:
inc     ax
mov     word [fs:A20_TEST_ADDR], ax
call    delay
cmp     ax, word [gs:A20_TEST_ADDR+0x10]
loop    a20_test_wait

pop     word [fs:A20_TEST_ADDR]
pop     ax
pop     cx
ret

empty_8042:
push    ecx
mov     ecx, 100000

empty_8042_loop:
dec     ecx
jz      empty_8042_end_loop

call    delay

in      al, 0x64                ; 8042状態ポート
test    al, 1                   ; 出力バッファをテスト
jz      no_output

call    delay
in      al, 0x60                ; 読む
jmp     empty_8042_loop

no_output:
test    al, 2                   ; 入力バッファがいっぱいになったか
jnz     empty_8042_loop         ; yes ? loopを回る

empty_8042_end_loop:
pop     ecx
ret

delay:
out     0x80, al
ret
