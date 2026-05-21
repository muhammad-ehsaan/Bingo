include emu8086.inc

.model small
.stack 200h

; DATA SEGMENT 

.data

card1    db 25 dup(0)       ; Player 1 card 5x5 flat
card2    db 25 dup(0)       ; Player 2 (or Computer) card 5x5 flat
mark1    db 25 dup(0)       ; Player 1 marks (0=no 1=yes)
mark2    db 25 dup(0)       ; Player 2 marks (0=no 1=yes)

; Pool used for shuffle (numbers 1 to 25)
pool     db 1,2,3,4,5,6,7,8,9,10
         db 11,12,13,14,15,16,17,18,19,20
         db 21,22,23,24,25

seed     dw 1              ; random seed
num      db 0              ; current picked number
turn     db 1              ; 1=P1 turn, 2=P2 turn
w1       db 0              ; P1 win flag
w2       db 0              ; P2 win flag
temp     db 0              ; temp variable
gameMode db 1              ; 1=P1 vs P2 (Secret Mode), 2=Player vs Computer

; MACROS  


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

; CODE SEGMENT

.code

; PROC: GetRandom
; Returns random number 1-25 in AL
; Uses seed variable + timer

GetRandom proc
    push bx
    push cx
    push dx

    mov ah, 00h
    int 1ah              ; CX:DX = timer ticks
    mov ax, seed
    add ax, dx
    add ax, cx
    inc ax
    mov seed, ax

    ; AX mod 25 + 1
    xor dx, dx
    mov cx, 25
    div cx                ; DX = remainder 0-24
    inc dx                ; DX = 1-25
    mov al, dl

    pop dx
    pop cx
    pop bx
    ret
GetRandom endp


; PROC: Shuffle
; Shuffles pool[] then copies into card at SI
; Fisher-Yates algorithm using loops

Shuffle proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; Step 1: Reset pool to 1,2,3...25
    mov si, 0
    mov al, 1
    mov cx, 25
ResetLP:
    mov pool[si], al
    inc si
    inc al
    loop ResetLP

    ; Step 2: Fisher-Yates shuffle
    ; i goes from 24 down to 1
    mov bx, 24            ; bx = i

ShufLP:
    cmp bx, 0
    je ShufDone

    ; Get random 0..bx
    push bx
    mov ah, 00h
    int 1ah
    mov ax, seed
    add ax, dx
    inc ax
    mov seed, ax
    pop bx

    push bx
    xor dx, dx
    inc bx                ; divisor = i+1
    div bx
    dec bx                ; restore bx = i
    ; DX = random index j (0..i)

    ; Swap pool[bx] and pool[dx]
    mov si, bx
    mov al, pool[si]      ; al = pool[i]
    mov si, dx
    mov ah, pool[si]      ; ah = pool[j]
    mov pool[si], al      ; pool[j] = old pool[i]
    mov si, bx
    mov pool[si], ah      ; pool[i] = old pool[j]

    pop bx
    dec bx
    jmp ShufLP

ShufDone:
    ; Step 3: Copy pool into card
    ; SI was pushed at start, pop it to get card pointer
    pop si                ; SI = card base (passed before call)

    mov cx, 25
    mov bx, 0
CopyLP:
    push si
    mov si, bx
    mov al, pool[si]      ; al = pool[bx]
    pop si
    ; now write to card: card[bx]
    push si
    add si, bx
    mov [si], al          ; card[bx] = al
    pop si
    inc bx
    loop CopyLP

    pop dx
    pop cx
    pop bx
    pop ax
    ret
Shuffle endp

; PROC: DisplayCards
; Hides/shows card screens based on privacy selection setting
; (P1 vs P2 with Secrecy System)

DisplayCards proc
    push ax
    push bx
    push cx
    push dx
    push si

    CLEAR_SCREEN          ; Clear console frame between turns to maintain secrecy

    ; If Player vs Computer, Player 1 display screen is always unhidden
    cmp gameMode, 2
    je D1Start

    ; If Player vs Player, load UI sheet based entirely on whose active loop turn it is
    cmp turn, 1
    je D1Start
    jmp D2Start

D1Start:
    ; --- Player 1 Card ---
    PNEWLINE
    printn '--- PLAYER 1 ---'
    printn '----------------'

    mov si, 0             ; si = cell index
    mov bx, 5             ; bx = outer row tracker

D1Outer:
    mov cx, 5             ; cx = inner column tracker
D1Inner:
    push cx               ; isolate nested counter registers

    ; Check mark array matrix
    mov al, mark1[si]
    cmp al, 1
    je D1Marked

    ; Print standard numerical configuration
    mov al, card1[si]
    call PrintNum
    jmp D1Next

D1Marked:
    ; Print masked layout block
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
    jmp DDone

D2Start:
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

DDone:
    PNEWLINE
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayCards endp


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
;  (Game Loops & Selection Screens)

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
