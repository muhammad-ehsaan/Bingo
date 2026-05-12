; ============================================================
; DATA SEGMENT  [ Muhammad Ehsan - Member 1 ]
; ============================================================
.DATA
    card1    DB 25 DUP(0)
    card2    DB 25 DUP(0)
    marked1  DB 25 DUP(0)
    marked2  DB 25 DUP(0)
    called   DB 75 DUP(0)

    cardPtr  DW 0
    markPtr  DW 0
    calledNum DB 0

    ; Seed for random   incremented each call to avoid repeats
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
; ============================================================
GetRandom PROC
    PUSH BX
    PUSH DX

    ; Mix timer with seed
    MOV AH, 00H
    INT 1AH                ; CX:DX = timer ticks

    MOV AX, seed
    ADD AX, DX             ; add timer low word
    ADD AX, CX             ; add timer high word
    INC AX                 ; always increment so same-tick calls differ
    MOV seed, AX           ; save new seed

    ; AX mod 75 + 1
    XOR DX, DX
    MOV BX, 75
    DIV BX                 ; DX = 0..74
    INC DX
    MOV AX, DX             ; AX = 1..75

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

    CALL GetRandom         ; AX = random 1-75
    MOV DL, AL             ; DL = candidate

    ; Uniqueness scan: check SI[0..BX-1]
    PUSH BX
    MOV CX, BX             ; CX = cells filled so far
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
    RET
GenerateCard ENDP