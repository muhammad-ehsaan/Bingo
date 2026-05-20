; Macro to print newline
PNEWLINE macro
    push ax
    push dx
    mov dl, 0dh
    mov ah, 02h
    int 21h
    mov dl, 0ah
    mov ah, 02h
    int 21h
    pop dx
    pop ax
endm

; Macro to print single character
PCHAR macro ch
    push ax
    push dx
    mov dl, ch
    mov ah, 02h
    int 21h
    pop dx
    pop ax
endm

; PROC: MarkBoth
; Marks the value in 'num' on both cards
; Uses loop with CX=25 and SI as index 

MarkBoth proc
    push ax
    push cx
    push si

    ; Mark on card1
    mov cx, 25
    mov si, 0
MB1:
    mov al, card1[si]
    cmp al, num
    jne MB1Skip
    mov mark1[si], 1
MB1Skip:
    inc si
    loop MB1

    ; Mark on card2
    mov cx, 25
    mov si, 0
MB2:
    mov al, card2[si]
    cmp al, num
    jne MB2Skip
    mov mark2[si], 1
MB2Skip:
    inc si
    loop MB2

    pop si
    pop cx
    pop ax
    ret
MarkBoth endp

; PROC: ReadNum
; Reads 1 or 2 digit number from keyboard
; Returns number in AL (0 if invalid)
; Uses INT 21h AH=01 

ReadNum proc
    push bx
    push cx
    push dx

    ; Read first char
    mov ah, 01h
    int 21h               ; AL = character
    mov bl, al

    ; Check if Enter
    cmp bl, 0dh
    je RDInvalid

    ; Check if digit
    cmp bl, '0'
    jb RDInvalid
    cmp bl, '9'
    ja RDInvalid
    sub bl, 48             ; convert ASCII to number 

    ; Read second char
    mov ah, 01h
    int 21h
    mov bh, al

    ; If Enter, single digit
    cmp bh, 0dh
    je RD1Dig

    ; Check second digit
    cmp bh, '0'
    jb RDInvalid2
    cmp bh, '9'
    ja RDInvalid2
    sub bh, 48

    ; Wait for Enter
    mov ah, 01h
    int 21h

    ; Build 2-digit: bl*10 + bh
    mov al, bl
    mov cl, 10
    mul cl                 ; AX = bl * 10
    add al, bh
    jmp RDDone

RD1Dig:
    mov al, bl
    jmp RDDone

RDInvalid2:
    ; consume Enter
    mov ah, 01h
    int 21h
RDInvalid:
    mov al, 0

RDDone:
    PNEWLINE
    pop dx
    pop cx
    pop bx
    ret
ReadNum endp

; MAIN  

main proc
    mov ax, @data
    mov ds, ax

    ; Title
    printn '============================'
    printn '   TWO PLAYER BINGO GAME'
    printn '============================'

    ; Generate Player 1 card
    lea si, card1
    call Shuffle

    ; Generate Player 2 card
    lea si, card2
    call Shuffle

    ; Show initial cards
    call DisplayCards

; GAME LOOP  

GameLoop:

    ; Whose turn?
    cmp turn, 1
    jne P2Turn

P1Turn:
    PNEWLINE
    print 'Player 1, pick a number (1-25): '
    jmp GetInput

P2Turn:
    PNEWLINE
    print 'Player 2, pick a number (1-25): '

GetInput:
    call ReadNum           ; AL = number

    ; Validate: must be 1-25
    cmp al, 0
    je BadInput
    cmp al, 25
    ja BadInput
    jmp GoodInput

BadInput:
    printn 'Invalid! Enter a number from 1 to 25.'
    jmp GetInput

GoodInput:
    mov num, al

    ; Mark on both cards
    call MarkBoth

    ; Display updated cards
    call DisplayCards

    ; Check win for both players
    call CheckWin1
    call CheckWin2

    ; Both win = draw
    cmp w1, 1
    jne ChkP1
    cmp w2, 1
    jne ChkP1
    PNEWLINE
    printn '****************************'
    printn '* BINGO! IT IS A DRAW!!!   *'
    printn '****************************'
    printn 'The game is over!'
    jmp GameEnd

ChkP1:
    cmp w1, 1
    jne ChkP2
    PNEWLINE
    printn '****************************'
    printn '* BINGO! PLAYER 1 WINS!!!  *'
    printn '****************************'
    printn 'Player 1 wins, the game is over!'
    jmp GameEnd

ChkP2:
    cmp w2, 1
    jne SwitchTurn
    PNEWLINE
    printn '****************************'
    printn '* BINGO! PLAYER 2 WINS!!!  *'
    printn '****************************'
    printn 'Player 2 wins, the game is over!'
    jmp GameEnd

SwitchTurn:
    ; Alternate turn: 1->2, 2->1
    cmp turn, 1
    jne SetT1
    mov turn, 2
    jmp GameLoop
SetT1:
    mov turn, 1
    jmp GameLoop

GameEnd:
    mov ah, 4ch
    int 21h

main endp

end main
