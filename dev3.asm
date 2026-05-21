; MACROS  [ Raja Abdulrehman - Member 2 ]

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

; Macro to clear the screen completely
CLEAR_SCREEN macro
    push ax
    push bx
    push cx
    push dx
    mov ah, 06h         ; Scroll up function
    mov al, 0           ; Clear entire screen
    mov bh, 07h         ; Normal text attribute (White on black)
    mov cx, 0000h       ; Top-left corner: (0,0)
    mov dx, 184Fh       ; Bottom-right corner: (24,79)
    int 10h
    
    ; Reset cursor back to top-left corner
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
endm

; PROC: GetComputerChoice
; Generates a random number that has NOT been marked on card2 yet
; (Computer vs Player Engine Part)

GetComputerChoice proc
    push bx
    push cx
    push si

GetCompLP:
    call GetRandom        ; Returns 1-25 in AL
    mov bl, al            ; bl = candidate selection number

    ; Search card2 mapping to pinpoint where this value lives
    mov cx, 25
    mov si, 0
FindLP:
    mov al, card2[si]
    cmp al, bl
    je CheckMarked
    inc si
    loop FindLP
    jmp GetCompLP         ; Safety branch fallback

CheckMarked:
    mov al, mark2[si]     ; Pull mark registry status
    cmp al, 1
    je GetCompLP          ; If already marked before, discard choice and reroll!
    
    mov al, bl            ; Safe selection found, return inside AL register

    pop si
    pop cx
    pop bx
    ret
GetComputerChoice endp

; PROC: MarkBoth
; Marks the value in 'num' on both cards

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

ReadNum proc
    push bx
    push cx
    push dx

    ; Read first char
    mov ah, 01h
    int 21h               
    mov bl, al

    ; Check if Enter
    cmp bl, 0dh
    je RDInvalid

    ; Check if digit
    cmp bl, '0'
    jb RDInvalid
    cmp bl, '9'
    ja RDInvalid
    sub bl, 48             

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
    mul cl                 
    add al, bh
    jmp RDDone

RD1Dig:
    mov al, bl
    jmp RDDone

RDInvalid2:
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

; MAIN METHOD ARCHITECTURE
; [(Game Loops & Selection Screens)

main proc
    mov ax, @data
    mov ds, ax

ShowMenu:
    CLEAR_SCREEN
    printn '============================'
    printn '   TWO PLAYER BINGO GAME'
    printn '============================'
    printn ' 1. Player 1 vs Player 2'
    printn ' 2. Player vs Computer'
    printn '============================'
    print  ' Enter your choice (1-2): '

    mov ah, 01h
    int 21h
    cmp al, '1'
    je SetPvP
    cmp al, '2'
    je SetPvC
    jmp ShowMenu         ; Boundary check fallback jump

SetPvP:
    mov gameMode, 1
    jmp StartGame

SetPvC:
    mov gameMode, 2

StartGame:
    ; Build structural card sheets
    lea si, card1
    call Shuffle

    lea si, card2
    call Shuffle

; EXECUTIVE RUNTIME LOOP 

GameLoop:

    ; Display current active screen map
    call DisplayCards

    ; Jump context branch based on current turn value
    cmp turn, 1
    jne P2Turn

P1Turn:
    PNEWLINE
    print 'Player 1, pick a number (1-25): '
    jmp GetInput

P2Turn:
    cmp gameMode, 2
    je CompTurn

    PNEWLINE
    print 'Player 2, pick a number (1-25): '
    jmp GetInput

CompTurn:
    PNEWLINE
    print 'Computer is thinking'
    PCHAR '.'
    PCHAR '.'
    call GetComputerChoice ; Pull machine calculation results
    
    ; System clock delay configuration (Int 15h)
    push ax
    mov ah, 86h
    mov cx, 0014h        
    mov dx, 5000h        
    int 15h              
    pop ax
    jmp GoodInput        

GetInput:
    call ReadNum           

    ; Boundary checks
    cmp al, 0
    je BadInput
    cmp al, 25
    ja BadInput
    jmp GoodInput

BadInput:
    printn 'Invalid! Enter a number from 1 to 25.'
    cmp turn, 1
    je P1Turn
    jmp P2Turn

GoodInput:
    mov num, al

    call MarkBoth

    ; Call validation audits
    call CheckWin1
    call CheckWin2

    ; Draw evaluation check
    cmp w1, 1
    jne ChkP1
    cmp w2, 1
    jne ChkP1
    
    call FinalGameDisplay  
    PNEWLINE
    printn '****************************'
    printn '* BINGO! IT IS A DRAW!!!   *'
    printn '****************************'
    printn 'The game is over!'
    jmp GameEnd

ChkP1:
    cmp w1, 1
    jne ChkP2
    
    call FinalGameDisplay  
    PNEWLINE
    printn '****************************'
    printn '* BINGO! PLAYER 1 WINS!!!  *'
    printn '****************************'
    printn 'Player 1 wins, the game is over!'
    jmp GameEnd

ChkP2:
    cmp w2, 1
    jne SwitchTurn
    
    call FinalGameDisplay  
    PNEWLINE
    printn '****************************'
    
    cmp gameMode, 2
    je PrintCompWinMsg
    printn '* BINGO! PLAYER 2 WINS!!!  *'
    jmp FinishWinMsg
PrintCompWinMsg:
    printn '* BINGO! COMPUTER WINS!!!  *'
FinishWinMsg:
    printn '****************************'
    printn 'The game is over!'
    jmp GameEnd

SwitchTurn:
    ; Context state flipper loop
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
