; ===========================
; Program: Accept a string input from the user,
;          Display it, and print its length in 2-digit hexadecimal.

; Macro: io
; Simplifies syscall usage for read/write/exit
; %1: syscall number (0 = read, 1 = write, 60 = exit)
; %2: file descriptor (0 = stdin, 1 = stdout)
; %3: address of buffer
; %4: number of bytes

%macro io 4
    mov rax, %1        ; Set syscall number
    mov rdi, %2        ; Set file descriptor (stdin/stdout)
    mov rsi, %3        ; Set buffer address
    mov rdx, %4        ; Set length
    syscall            ; Make the syscall
%endmacro

section .data
    ; Static messages
    intro db "Write 64 ALP to accept a string from user and display the length.", 10
    db "Name: sagar", 10
    db "Roll no: 7248", 10
    db "Date: 10/02/25", 10
    intro_len equ $ - intro            ; Length of the entire intro block

    prompt db "Enter string: ", 10     ; Prompt user for input
    prompt_len equ $ - prompt

    output db "The length of string is: ", 10  ; Message before displaying length
    output_len equ $ - output

    newline db 10                      ; Newline character (\n)

section .bss  ; hholds varibles
    input resb 20      ; Reserve 20 bytes to store user input
    length resb 1      ; To store actual length of input string (1 byte)
    hexstr resb 2      ; To store 2-digit ASCII hex of length

section .text
    global _start     


_start:
    ; Print the intro message
    io 1, 1, intro, intro_len  ; 

    ; Prompt user to enter a string
    io 1, 1, prompt, prompt_len

    ; Read input from user into `input` buffer
    io 0, 0, input, 20

    ; After syscall, RAX contains number of bytes read (includes Enter key)
    ; Subtract 1 to remove newline character from length
    dec rax
    mov [length], al       ; Store the actual input length in memory

    ; Display output message
    io 1, 1, output, output_len

    ; Move length into BL register for conversion
    mov bl, [length]
    call to_hex            ; Call function to convert length to hex string

    ; Exit the program gracefully
    mov rax, 60            ; Syscall: exit
    xor rdi, rdi           ; Exit code 0
    syscall

; ----------------------------------------
; Function: to_hex
; Converts the value in BL to 2-digit ASCII hexadecimal
; Result is stored in `hexstr` buffer
; ----------------------------------------
to_hex:
    mov rsi, hexstr     ; Set pointer to hexstr buffer
    mov rcx, 2          ; We need to convert 2 hex digits (8-bit = 2 hex digits)

.convert_loop:
    rol bl, 4           ; Rotate BL left 4 bits to bring high nibble first, then low
    mov al, bl          ; Move current nibble to AL
    and al, 0Fh         ; Mask upper 4 bits, retain lower nibble

    cmp al, 9           ; Is the value <= 9?
    jbe .is_digit       ; Yes: it's a decimal digit

    add al, 7           ; No: Adjust for ASCII A–F

.is_digit:
    add al, '0'         ; Convert to ASCII ('0'..'9' or 'A'..'F')
    mov [rsi], al       ; Store the character in buffer
    inc rsi             ; Move to next byte
    loop .convert_loop  ; Loop twice

    ; Print the resulting hex string
    io 1, 1, hexstr, 2
    io 1, 1, newline, 1
    ret
