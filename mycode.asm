DisplayCard PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV BX, 0
    MOV CX, 5              ; 5 rows

ROWLOOP:
    PUSH CX
    MOV CX, 5              ; 5 cols

COLLOOP:
    MOV SI, markPtr
    CMP BYTE PTR [SI+BX], 1
    JNE SHOWNUM

    ; Marked cell ? print " *  "
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    MOV DL, '*'
    MOV AH, 02H
    INT 21H
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    JMP CELLDONE

SHOWNUM:
    MOV SI, cardPtr
    MOV AL, [SI+BX]
    CALL PrintNumber

CELLDONE:
    INC BX
    LOOP COLLOOP

    NEWLINE
    POP CX
    LOOP ROWLOOP

    NEWLINE
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayCard ENDP