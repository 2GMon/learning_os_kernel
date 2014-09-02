[org 0]
[bits 16]

start:
    mov ax, cs              ; CSには0x1000が入っている
    mov ds, ax
    mov ax, ax
    mov ss, ax

    lea esi, [msgKernel]    ; 文字列があるアドレスをesiに代入する
    mov ax, 0xB800
    mov es, ax              ; esに0xB800を入れる
    mov edi, 0              ; 画面の一番前から始める
    call printf
    jmp $

printf:
    push eax                ; すでにあったeax値をスタックに保存しておく

printf_loop:
    mov al, byte [esi]      ; esiが指しているアドレスから文字を1つ持ってくる
    mov byte [es:edi], al   ; 文字を画面に表示する
    or  al, al              ; alが0なのかを調べる
    jz  printf_end          ; 0であれば、printf_endにジャンプ
    inc edi                 ; 0でなければ、ediを1つ増やして
    mov byte [es:edi], 0x06 ; 文字の色と背景色の値を入れる
    inc esi                 ; 次の文字を取り出すためにesiを1つ増やす
    inc edi                 ; 画面に次の文字を表示するためにediを1つ増やす
    jmp printf_loop         ; ループを回す

printf_end:
    pop eax                 ; スタックに保存しておいたeaxを再び取り出す
    ret                     ; 呼び出し元に戻る

msgKernel   db  "We are in kernel program", 0
