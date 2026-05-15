PrintNum proc
    push ax
    push bx
    push dx

    mov ah, 0
    mov bl, 10
    div bl                ; AL=tens, AH=ones

    ; Print tens digit
    push ax
    mov dl, al
    add dl, 48            ; convert to ASCII like lab 3
    mov ah, 02h
    int 21h
    pop ax

    ; Print ones digit
    mov dl, ah
    add dl, 48
    mov ah, 02h
    int 21h

    ; Space after number
    PCHAR ' '

    pop dx
    pop bx
    pop ax
    ret
PrintNum endp

; PROC: DisplayCards
; Shows both 5x5 cards using nested loops
; Outer loop = rows (saved with push cx like Lab 7)
; Inner loop = columns

DisplayCards proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; --- Player 1 Card ---
    PNEWLINE
    printn '--- PLAYER 1 ---'
    printn '----------------'

    mov si, 0             ; si = cell index
    mov bx, 5             ; bx = outer loop counter (rows)

D1Outer:
    mov cx, 5             ; cx = inner loop (columns)
D1Inner:
    push cx               ; save inner cx (nested loop - Lab 7 style)

    ; Check if marked
    mov al, mark1[si]
    cmp al, 1
    je D1Marked

    ; Not marked: print number
    mov al, card1[si]
    call PrintNum
    jmp D1Next

D1Marked:
    ; Print "XX " for marked
    PCHAR 'X'
    PCHAR 'X'
    PCHAR ' '

D1Next:
    inc si
    pop cx
    loop D1Inner

    PNEWLINE
    dec bx
    cmp bx, 0
    jne D1Outer

    ; --- Player 2 Card ---
    PNEWLINE
    printn '--- PLAYER 2 ---'
    printn '----------------'

    mov si, 0
    mov bx, 5

D2Outer:
    mov cx, 5
D2Inner:
    push cx

    mov al, mark2[si]
    cmp al, 1
    je D2Marked

    mov al, card2[si]
    call PrintNum
    jmp D2Next

D2Marked:
    PCHAR 'X'
    PCHAR 'X'
    PCHAR ' '

D2Next:
    inc si
    pop cx
    loop D2Inner

    PNEWLINE
    dec bx
    cmp bx, 0
    jne D2Outer

    PNEWLINE

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayCards endp
