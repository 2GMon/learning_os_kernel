[org 0]
[bits 16]
    jmp 0x07C0:start        ; far jmp

start:
    mov ax, cs              ; csには0x07C0が入っている
    mov ds, ax              ; dsをcsと同じにする

    mov ax, 0xB800          ; ビデオメモリのセグメントを
    mov es, ax              ; esレジスタにいれる
    mov di, 0               ; 一番上の頭の部分から書く
    mov ax, word [msgBack]  ; 書く予定のデータのアドレスを指定する
    mov cx, 0x7FF           ; 画面全体に書くためには
                            ; 0x7FF(2047)個のWORDが必要

paint:
    mov word [es:di], ax    ; ビデオメモリに書く
    add di, 2               ; 1つのWORDを書いたので、2を加える
    dec cx                  ; 1つのWORDを書いたので、CXの値を1つ引く
    jnz paint               ; CXが0でなければpaintにジャンプ
                            ; 残りを書く

    mov edi, 0              ; 一番上の頭の部分に書く
    mov byte [es:edi], 'A'  ; ビデオメモリに書く
    inc edi                 ; 1つのBYTEを書いたので、1を加える
    mov byte [es:edi], 0x06 ; 背景色を書く
    inc edi                 ; 1つのBYTEを書いたので、1を加える
    mov byte [es:edi], 'B'
    inc edi
    mov byte [es:edi], 0x06
    inc edi
    mov byte [es:edi], 'C'
    inc edi
    mov byte [es:edi], 0x06
    inc edi
    mov byte [es:edi], '1'
    inc edi
    mov byte [es:edi], 0x06
    inc edi
    mov byte [es:edi], '2'
    inc edi
    mov byte [es:edi], 0x06
    inc edi
    mov byte [es:edi], '3'
    inc edi
    mov byte [es:edi], 0x06

    jmp $                   ; ここで無限ループに入る

msgBack db  '.', 0xE7       ; 背景に使う文字

times   510 - ($ - $$) db 0 ; ここから509番地まで0で詰める
        dw  0xAA55          ; 510番地に0x55を511番地に0xAAを入れておく
