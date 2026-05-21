; PROC: PrintNum
; Prints value in AL as 2-digit number with space

PrintNum proc
    push ax
    push bx
    push dx

    mov ah, 0
    mov bl, 10
    div bl                ; AL=tens, AH=ones

    push ax
    mov dl, al
    add dl, 48            
    mov ah, 02h
    int 21h
    pop ax

    mov dl, ah
    add dl, 48
    mov ah, 02h
    int 21h

    PCHAR ' '

    pop dx
    pop bx
    pop ax
    ret
PrintNum endp

; PROC: FinalGameDisplay
; Displays BOTH cards completely visible at game end

FinalGameDisplay proc
    push ax
    push bx
    push cx
    push dx
    push si

    CLEAR_SCREEN
    printn '========================================'
    printn '         FINAL GAME CARD SHEETS         '
    printn '========================================'
    
    ; --- Display Card 1 ---
    PNEWLINE
    printn '--- PLAYER 1 ---'
    mov si, 0
    mov bx, 5
DF1Outer:
    mov cx, 5
DF1Inner:
    push cx
    cmp mark1[si], 1
    je DF1Marked
    mov al, card1[si]
    call PrintNum
    jmp DF1Next
DF1Marked:
    PCHAR 'X'
    PCHAR 'X'
    PCHAR ' '
DF1Next:
    inc si
    pop cx
    loop DF1Inner
    PNEWLINE
    dec bx
    cmp bx, 0
    jne DF1Outer

    ; --- Display Card 2 ---
    PNEWLINE
    cmp gameMode, 2
    je DFCpuTitle
    printn '--- PLAYER 2 ---'
    jmp DF2Start
DFCpuTitle:
    printn '--- COMPUTER ---'
DF2Start:
    mov si, 0
    mov bx, 5
DF2Outer:
    mov cx, 5
DF2Inner:
    push cx
    cmp mark2[si], 1
    je DF2Marked
    mov al, card2[si]
    call PrintNum
    jmp DF2Next
DF2Marked:
    PCHAR 'X'
    PCHAR 'X'
    PCHAR ' '
DF2Next:
    inc si
    pop cx
    loop DF2Inner
    PNEWLINE
    dec bx
    cmp bx, 0
    jne DF2Outer

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
FinalGameDisplay endp

; PROC: CheckWin1
; Checks mark1 rows, columns, and diagonals

CheckWin1 proc
    push ax
    push bx
    push cx
    push si

    mov w1, 0

    ; --- Check 5 rows ---
    mov si, 0             
    mov bx, 5             
CW1R:
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
    mov si, 0             
    mov bx, 5
CW1C:
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

    ; --- Main diagonal: 0,6,12,18,24 ---
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

; PROC: CheckWin2
; Same logic as CheckWin1 but for Player 2 (mark2)

CheckWin2 proc
    push ax
    push bx
    push cx
    push si

    mov w2, 0

    ; --- Check 5 rows ---
    mov si, 0
    mov bx, 5
CW2R:
    mov al, mark2[si]
    cmp al, 1
    jne CW2RN
    mov al, mark2[si+1]
    cmp al, 1
    jne CW2RN
    mov al, mark2[si+2]
    cmp al, 1
    jne CW2RN
    mov al, mark2[si+3]
    cmp al, 1
    jne CW2RN
    mov al, mark2[si+4]
    cmp al, 1
    jne CW2RN
    mov w2, 1
    jmp CW2Done
CW2RN:
    add si, 5
    dec bx
    cmp bx, 0
    jne CW2R

    ; --- Check 5 columns ---
    mov si, 0
    mov bx, 5
CW2C:
    mov al, mark2[si]
    cmp al, 1
    jne CW2CN
    mov al, mark2[si+5]
    cmp al, 1
    jne CW2CN
    mov al, mark2[si+10]
    cmp al, 1
    jne CW2CN
    mov al, mark2[si+15]
    cmp al, 1
    jne CW2CN
    mov al, mark2[si+20]
    cmp al, 1
    jne CW2CN
    mov w2, 1
    jmp CW2Done
CW2CN:
    inc si
    dec bx
    cmp bx, 0
    jne CW2C

    ; --- Main diagonal ---
    cmp mark2[0], 1
    jne CW2AD
    cmp mark2[6], 1
    jne CW2AD
    cmp mark2[12], 1
    jne CW2AD
    cmp mark2[18], 1
    jne CW2AD
    cmp mark2[24], 1
    jne CW2AD
    mov w2, 1
    jmp CW2Done

CW2AD:
    ; --- Anti diagonal ---
    cmp mark2[4], 1
    jne CW2Done
    cmp mark2[8], 1
    jne CW2Done
    cmp mark2[12], 1
    jne CW2Done
    cmp mark2[16], 1
    jne CW2Done
    cmp mark2[20], 1
    jne CW2Done
    mov w2, 1

CW2Done:
    pop si
    pop cx
    pop bx
    pop ax
    ret
CheckWin2 endp
