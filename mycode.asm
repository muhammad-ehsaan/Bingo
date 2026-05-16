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
    add dl, 48            ; convert to ASCII 
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
; Outer loop = rows 
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
    push cx               ; save inner cx 

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

; PROC: CheckWin1
; Checks mark1 for complete row/col/diagonal
; Returns: w1 = 1 if win, 0 if not

CheckWin1 proc
    push ax
    push bx
    push cx
    push si

    mov w1, 0

    ; --- Check 5 rows ---
    mov si, 0             ; row start
    mov bx, 5             ; 5 rows
CW1R:
    ; Check 5 cells in row: mark1[si] to mark1[si+4]
    mov al, mark1[si]
    cmp al, 1
    jne CW1RN
    mov al, mark1[si+1]
    cmp al, 1
    jne CW1RN
    mov al, mark1[si+2]
    cmp al, 1
    jne CW1RN
    mov al, mark1[si+3]
    cmp al, 1
    jne CW1RN
    mov al, mark1[si+4]
    cmp al, 1
    jne CW1RN
    mov w1, 1
    jmp CW1Done
CW1RN:
    add si, 5
    dec bx
    cmp bx, 0
    jne CW1R

    ; --- Check 5 columns ---
    mov si, 0             ; column start
    mov bx, 5
CW1C:
    ; Column indices: si, si+5, si+10, si+15, si+20
    mov al, mark1[si]
    cmp al, 1
    jne CW1CN
    mov al, mark1[si+5]
    cmp al, 1
    jne CW1CN
    mov al, mark1[si+10]
    cmp al, 1
    jne CW1CN
    mov al, mark1[si+15]
    cmp al, 1
    jne CW1CN
    mov al, mark1[si+20]
    cmp al, 1
    jne CW1CN
    mov w1, 1
    jmp CW1Done
CW1CN:
    inc si
    dec bx
    cmp bx, 0
    jne CW1C

    ; Main diagonal: 0,6,12,18,24 
    cmp mark1[0], 1
    jne CW1AD
    cmp mark1[6], 1
    jne CW1AD
    cmp mark1[12], 1
    jne CW1AD
    cmp mark1[18], 1
    jne CW1AD
    cmp mark1[24], 1
    jne CW1AD
    mov w1, 1
    jmp CW1Done

CW1AD:
    ; --- Anti diagonal: 4,8,12,16,20 ---
    cmp mark1[4], 1
    jne CW1Done
    cmp mark1[8], 1
    jne CW1Done
    cmp mark1[12], 1
    jne CW1Done
    cmp mark1[16], 1
    jne CW1Done
    cmp mark1[20], 1
    jne CW1Done
    mov w1, 1

CW1Done:
    pop si
    pop cx
    pop bx
    pop ax
    ret
CheckWin1 endp
