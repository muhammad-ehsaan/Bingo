.DATA
    card1    DB 25 DUP(0)
    card2    DB 25 DUP(0)
    marked1  DB 25 DUP(0)
    marked2  DB 25 DUP(0)
    called   DB 75 DUP(0)

    cardPtr  DW 0
    markPtr  DW 0
    calledNum DB 0
    seed     DW 1

    msgP1     DB "== PLAYER 1 CARD ==",13,10,"$"
    msgP2     DB "== PLAYER 2 CARD ==",13,10,"$"
    msgCalled DB 13,10,">>> Called Number: $"
    msgSep    DB "--------------------",13,10,"$"
    msgP1Win  DB 13,10,"*** PLAYER 1 WINS - BINGO! ***",13,10,"$"
    msgP2Win  DB 13,10,"*** PLAYER 2 WINS - BINGO! ***",13,10,"$"
    msgDraw   DB 13,10,"*** IT IS A DRAW - BINGO! ***",13,10,"$"
    msgNL     DB 13,10,"$"
    msgSpc    DB " $"

; PROC: GetRandom
; Returns a pseudo-random number in AX (1 to 75)
GetRandom PROC
    PUSH BX
    PUSH DX

    ; Mix timer with seed
    MOV AH, 00H
    INT 1AH               

    MOV AX, seed
    ADD AX, DX             ; add timer low word
    ADD AX, CX             ; add timer high word
    INC AX                 ; always increment so same-tick calls differ
    MOV seed, AX           ; save new seed

    ; AX mod 75 + 1
    XOR DX, DX
    MOV BX, 75
    DIV BX                
    INC DX
    MOV AX, DX            

    POP DX
    POP BX
    RET
GetRandom ENDP

; ============================================================
; PROC: GenerateCard
; ============================================================
GenerateCard PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV SI, cardPtr
    MOV BX, 0              ; fill index

GENNEXT:
    CMP BX, 25
    JGE GENDONE

    CALL GetRandom        
    MOV DL, AL             
    PUSH BX
    MOV CX, BX             
    MOV BX, 0

    CMP CX, 0
    JE  UNIQUE

SCANLOOP:
    CMP [SI+BX], DL
    JE  DUPLICATE
    INC BX
    LOOP SCANLOOP
    JMP UNIQUE

DUPLICATE:
    POP BX
    JMP GENNEXT

UNIQUE:
    POP BX
    MOV [SI+BX], DL        ; store number
    INC BX
    JMP GENNEXT

GENDONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX



.model small
.stack 200h

; ============================================================
; UPDATED DATA SEGMENT  
; ============================================================
.data

card1    db 25 dup(0)       ; Player 1 card 5x5 flat
card2    db 25 dup(0)       ; Player 2 card 5x5 flat
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

; ============================================================
; UPDATED  PROC: GetRandom
; ============================================================
GetRandom proc
    push bx
    push cx
    push dx

    mov ah, 00h
    int 1ah              
    mov ax, seed
    add ax, dx
    add ax, cx
    inc ax
    mov seed, ax

    ; AX mod 25 + 1
    xor dx, dx
    mov cx, 25
    div cx                
    inc dx               
    mov al, dl

    pop dx
    pop cx
    pop bx
    ret
GetRandom endp

    RET
GenerateCard ENDP
