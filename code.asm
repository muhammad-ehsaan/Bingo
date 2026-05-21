include emu8086.inc

.model small
.stack 200h

; ============================================================
; DATA SEGMENT  [ Muhammad Ehsan - Member 1 ]
; ============================================================
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

; ============================================================
; CODE SEGMENT
; ============================================================
.code

; ============================================================
; PROC: GetRandom
; Returns random number 1-25 in AL
; Uses seed variable + timer
; [ Muhammad Ehsan - Member 1 ]
; ============================================================
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

; ============================================================
; PROC: Shuffle
; Shuffles pool[] then copies into card at SI
; Fisher-Yates algorithm using loops
; [ Muhammad Ehsan - Member 1 ]
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

; ============================================================
; PROC: DisplayCards
; Hides/shows card screens based on privacy selection setting
; [ Muhammad Ehsan - Member 1 ] -> (P1 vs P2 with Secrecy System)
; ============================================================
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
