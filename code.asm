.CODE

PRINT_STR MACRO msg
    PUSH AX
    PUSH DX
    LEA DX, msg
    MOV AH, 09H
    INT 21H
    POP DX
    POP AX
ENDM

NEWLINE MACRO
    PUSH AX
    PUSH DX
    LEA DX, msgNL
    MOV AH, 09H
    INT 21H
    POP DX
    POP AX
ENDM

CallNumber PROC
    PUSH AX
    PUSH BX
    PUSH SI

TRYAGAIN:
    CALL GetRandom         
    MOV BX, AX
    DEC BX                

    LEA SI, called
    CMP BYTE PTR [SI+BX], 1
    JE  TRYAGAIN           

    MOV BYTE PTR [SI+BX], 1
    INC BX
    MOV calledNum, BL

    POP SI
    POP BX
    POP AX
    RET
CallNumber ENDP

MarkCard PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV CX, 25
    MOV BX, 0

MARKLOOP:
    MOV SI, cardPtr
    MOV AL, [SI+BX]        ; card[BX]

    CMP AL, calledNum
    JNE MARKNEXT

    MOV SI, markPtr
    MOV BYTE PTR [SI+BX], 1  ; marked[BX] = 1

MARKNEXT:
    INC BX
    LOOP MARKLOOP

    POP SI
    POP CX
    POP BX
    POP AX
    RET
MarkCard ENDP