
%macro io 4
    ; Simplified syscall macro for read/write/exit
    ; %1: syscall number, %2: fd, %3: buffer, %4: length
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    syscall
%endmacro

section .data
    msg1 db "Write an X86/64 ALP to accept five hexadecimal numbers from user and store them in an array and display the accepted numbers.", 10
    msg1len equ $ - msg1

    msg2 db "Enter five 64-bit hexadecimal numbers:", 10
    msg2len equ $ - msg2

    msg3 db "The five 64-bit hexadecimal numbers are:", 10
    msg3len equ $ - msg3

    newline db 10

section .bss
    ascii  resb 17       ; buffer to store 16-char hex string + newline
    hexnum resq 5        ; array to store 5 x 64-bit numbers

section .text
    global _start

_start:
    ; Display instructions
    io 1, 1, msg1, msg1len
    io 1, 1, msg2, msg2len

    ; Read 5 hex numbers from user
    mov rcx, 5           ; loop counter for 5 numbers
    mov rsi, hexnum      ; pointer to array

read_loop:
    push rcx
    push rsi

    io 0, 0, ascii, 17   ; read input from user (16 hex digits + newline)
    call ascii_hex64     ; convert ASCII hex -> binary (in RBX)
    
    pop rsi
    mov [rsi], rbx       ; store 64-bit result
    add rsi, 8           ; move to next array slot
    pop rcx
    loop read_loop

    ; Display the message before output
    io 1, 1, msg3, msg3len

    ; Display 5 stored hex numbers
    mov rcx, 5
    mov rsi, hexnum

print_loop:
    push rcx
    push rsi

    mov rbx, [rsi]       ; load number from array
    call hex_ascii64     ; convert to ASCII hex string

    pop rsi
    add rsi, 8
    pop rcx
    loop print_loop

    ; Exit the program
    mov rax, 60
    xor rdi, rdi
    syscall

; ----------------------------------
; Convert ASCII hex string to 64-bit binary (in RBX)
; Expects ASCII string at [ascii]
; ----------------------------------
ascii_hex64:
    mov rsi, ascii
    xor rbx, rbx         ; clear result
    mov rcx, 16          ; loop for 16 characters

a2h_loop:
    rol rbx, 4           ; make space for new nibble (shift left 4 bits)
    mov al, [rsi]        ; load next ASCII char
    cmp al, '9'
    jbe .convert_digit   ; if <= '9', it's a digit
    sub al, 7h           ; adjust ASCII A-F (or a-f)

.convert_digit:
    sub al, '0'          ; convert ASCII to value (0-15)
    add bl, al           ; add nibble to result
    inc rsi
    loop a2h_loop
    ret

; ----------------------------------
; Convert 64-bit binary number (in RBX) to ASCII hex string
; Result stored in [ascii]
; ----------------------------------
hex_ascii64:
    mov rsi, ascii
    mov rcx, 16          ; 64-bit = 16 hex digits

h2a_loop:
    rol rbx, 4           ; get next nibble (left rotate)
    mov al, bl
    and al, 0Fh          ; isolate lowest 4 bits

    cmp al, 9
    jbe .digit
    add al, 7h           ; for A-F

.digit:
    add al, '0'          ; convert to ASCII
    mov [rsi], al
    inc rsi
    loop h2a_loop

    io 1, 1, ascii, 16   ; print the 16-char hex string
    io 1, 1, newline, 1
    ret
