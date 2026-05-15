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
; Uses loop with CX=25 and SI as index (Lab 8 style)

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
