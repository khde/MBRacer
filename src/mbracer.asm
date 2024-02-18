org 0x7c00
bits 16

%define VGA_VMEM_OFFSET 0xb800

%define WHITE 0b11110000
%define BLACK 0b00000000
%define RED 0b01000000
%define MAGENTA 0b01010000

; Character + Attribute
%define SQUARE_WHITE 0b1111000000100000
%define SQUARE_BLACK 0b0000000000100000
%define SQUARE_GREEN 0b0010000000100000
%define SQUARE_BLUE 0b0001000000100000
%define SQUARE_RED 0b0100000000100000
%define SQUARE_GREY 0b1000000000100000

; Valid x-positions
%define s_left 28
%define s_right 43


init:
    ; Data Segment should be here
    xor ax, ax
    mov ds, ax

    ; Set up Stack Segment
    mov ax, 0x2000
    mov ss, ax
    mov sp, 0x1000

    ; Video Mode 80x25 Text Mode
    ; mov ah, 0x0
    ; mov al, 0x2
    ; int 0x10

    ; Hide Cursor
    mov ah, 0x1
    mov cx, 0x2607
    int 0x10

    ; Move VGA Video Memory Offset into gs
    mov ax, VGA_VMEM_OFFSET
    mov gs, ax

    call srand


init_round:
    mov [gaming], byte 0x1
    mov [score], byte 0x1
    mov [waiting], word 0x9777

    mov [px], byte s_right
    mov [py], byte 16

    mov [ex], byte s_left
    mov [ey], byte 27


gameloop:
    cmp [gaming], byte 0x0
    jne .l1
    jmp init_round

.l1:
    call draw
    call input
    call logic

    ; Waiting
    mov ah, 0x86
    mov cx, 0x0000
    mov dx, [waiting]
    int 0x15

    jmp gameloop


draw:
    call clear_screen

    ; Draw Street, just a square
    xor dx, dx
.l2:
    mov bx, 25
.l1:
    mov di, bx
    mov si, dx
    mov cx, SQUARE_GREY
    call put_char

    inc bx
    cmp bx, 55
    jl .l1

    inc dx
    cmp dx, 24
    jle .l2

    ; Player Car
    movzx di, byte [px]
    movzx si, byte [py]
    call draw_car

    ; Enemy Car
    movzx di, byte [ex]
    movzx si, byte [ey]
    call draw_car

    ret


; x: di
; y: si
draw_car:
    push bp,
    mov bp, sp

    push di
    mov bx, car1
    xor ax, ax
.l2:
    mov di, [bp-2]
    xor dx, dx
.l1:
    ; If Byte is MAGENTA skip it, as some value
    ; to representate "no drawing" is needed
    cmp [bx], byte MAGENTA
    je .continue

    mov ch, byte [bx]
    mov cl, 0b100000

    call put_char

.continue:
    inc di
    inc dx
    inc bx
    cmp dx, 9
    jne .l1

    inc si
    inc ax
    cmp ax, 5
    jne .l2

    leave
    ret


input:
    ; Check for keypress
    mov ah, 0x1
    int 0x16
    jz .exit  ; Zero Flag is set if no keypress there

    mov ah, 0x0
    int 0x16

    mov bx, px

    ; Check going to left lane
    cmp al, "a"
    jne .l2
    mov [bx], byte s_left
    jmp .exit

.l2:
    ; Check going to right lane
    cmp al, "d"
    jne .exit
    mov [bx], byte s_right

.exit:
    ret


logic:
    inc byte [ey]

    ; Check for collision of enemy and player
    ; Check if in front of player
    mov al, [ey]
    add al, 6
    cmp al, [py]
    jl .l3

    ; Check if behind of player
    mov al, [py]
    add al, 6
    cmp al, [ey]
    jl .l3

    ; Check if same lane
    mov al, [ex]
    cmp al, [px]
    jne .l3
    ; Game Over
    call draw  ; Draw screen where you failed
    mov [gaming], byte 0x0

.l3:
    ; Check if enemy car reached bottom of screen
    cmp [ey], byte 28
    jne .exit

    call rand

    xor dx, dx
    mov bx, 2
    div bx

    cmp dx, 0
    jne .l1
    mov dl, s_left
    jmp .l2
.l1:
    mov dl, s_right
.l2:
    mov [ex], dl
    mov [ey], byte 0
    inc byte [score]
    sub [waiting], word 0x210

.exit:
    ret


; return: ax
rand:
    mov ax, [seed]
    mov bx, 42321
    imul bx
    add ax, 12341
    mov [seed], ax

    xor dx, dx
    mov bx, 62123
    idiv bx

    xor dx, dx
    mov bx, 31164
    idiv bx

    mov ax, dx
    ret


srand:
    ; Get seconds from RTC
    ; Seconds
    xor ax, ax
    mov al, 0x0
    out 0x70, al
    in al, 0x71
    mov dl, al

    ; Minutes
    mov al, 0x2
    out 0x70, al
    in al, 0x71
    mov dh, al

    mov ax, dx
    mul ax
    mov dx, ax

    mov [seed], dx
    ret


; x: di
; y: si
; character + attribute: cx
put_char:
    push di
    push si
    push cx
    push ax
    push dx

    ; Don't touch memory outside of Video Memory (at least in +y)
    cmp si, 25
    jge .exit

    mov ax, 160
    mul si
    sal di, 1
    add ax, di
    mov di, ax
    mov word [gs:di], cx

.exit:
    pop dx
    pop ax
    pop cx
    pop si
    pop di
    ret


clear_screen:
    xor di, di
.loop:
    mov word [gs:di], SQUARE_GREEN
    add di, 2
    cmp di, 80 * 25 * 2
    jb .loop
    ret


; Data
    gaming db 0x0
    seed dw 0x0
    score db 0x0
    waiting dw 0x0

    ; Player position
    px db 0
    py db 0

    ; Enemy position
    ex db 0
    ey db 0

car1:
    db BLACK, RED, RED, RED, RED, RED, RED, RED, BLACK
    db BLACK, RED, RED, RED, RED, RED, RED, RED, BLACK
    db MAGENTA, RED, RED, RED, RED, RED, RED, RED, MAGENTA
    db BLACK, RED, RED, RED, RED, RED, RED, RED, BLACK
    db BLACK, RED, RED, RED, RED, RED, RED, RED, BLACK

times 510 - ($ - $$) db 0x0
db 0x55, 0xaa
