; X86-64 NASM Program to:

%macro write 2
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro read 2
    mov rax, 0
    mov rdi, 0
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

; === Data Section ===
section .data
    msg_intro db "Hex <-> BCD Converter",10,"Name: Sagar Sharma",10,"Roll No: 7248",10,10
    intro_len equ $-msg_intro

    msg_menu db "1. Hex to BCD",10,"2. BCD to Hex",10,"3. Exit",10,"Enter your choice: "
    menu_len equ $-msg_menu

    msg_input db "Enter number: "
    inplen equ $-msg_input

    endl db 10


section .bss
    choice resb 2
    hex_input resb 5
    bcd_input resb 6
    buffer resb 5
    output resb 4

; === Text Section ===
section .text
    global _start

_start:
    write msg_intro, intro_len

main_menu:
    write msg_menu, menu_len
    read choice, 2

    cmp byte [choice], '1'
    je hex_to_bcd

    cmp byte [choice], '2'
    je bcd_to_hex

    cmp byte [choice], '3'
    je exit_program

    jmp main_menu

; === Case 1: Hex to BCD ===
hex_to_bcd:
    write msg_input, inplen
    read hex_input, 5

    call ascii_to_hex         ; Convert input string to binary (in BX)
    mov ax, bx
    mov bx, 10                ; Base 10 for division
    mov rcx, 5

convert_loop:
    xor rdx, rdx
    div bx                    ; AX / 10 → Quotient in AX, Remainder in DX
    push dx                   ; Save remainder
    loop convert_loop

    mov rsi, buffer
    mov rcx, 5

print_bcd:
    pop ax
    add al, '0'
    mov [rsi], al
    inc rsi
    loop print_bcd

    write buffer, 5
    write endl, 1
    jmp main_menu

; === Case 2: BCD to Hex ===
bcd_to_hex:
    write msg_input, inplen
    read bcd_input, 6

    mov rsi, bcd_input
    mov rcx, 5
    mov rax, 0
    mov bx, 10

bcd_loop:
    mul bx                  ; RAX *= 10
    mov dl, [rsi]
    sub dl, '0'             ; Convert ASCII to number
    add al, dl              ; Add digit
    inc rsi
    loop bcd_loop

    mov bx, ax
    call hex_to_ascii
    write output, 4
    write endl, 1
    jmp main_menu

; === Exit ===
exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall

; === Helper: Convert ASCII hex string to binary value (BX) ===
ascii_to_hex:
    mov bx, 0
    mov rsi, hex_input
    mov rcx, 4

ascii_loop:
    rol bx, 4               ; Shift BX left by 4 bits
    mov al, [rsi]
    cmp al, '9'
    jbe is_digit
    sub al, 7h              ; Adjust A–F
is_digit:
    sub al, '0'
    add bl, al
    inc rsi
    loop ascii_loop
    ret

; === Helper: Convert binary BX to ASCII hex string (output in [output]) ===
hex_to_ascii:
    mov rsi, output
    mov rcx, 4

hex_print:
    rol bx, 4
    mov al, bl
    and al, 0Fh
    cmp al, 9
    jbe hex_digit
    add al, 7h
hex_digit:
    add al, '0'
    mov [rsi], al
    inc rsi
    loop hex_print
    ret
