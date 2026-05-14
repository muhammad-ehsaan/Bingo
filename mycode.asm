PrintNumber PROC
    PUSH AX
    PUSH BX
    PUSH DX

    MOV AH, 0
    MOV BL, 10
    DIV BL      