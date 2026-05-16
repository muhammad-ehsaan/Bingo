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





; ============================================================
; PROC: Shuffle
; ============================================================
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
    ; we use: mov [si+bx], al    but [si+bx] is not valid
    ; so we add bx to si temporarily
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
