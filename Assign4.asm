
; Macros for syscall abstraction

%macro io 4
    mov rax, %1         ; Syscall number: 0 = read, 1 = write
    mov rdi, %2         ; File descriptor: 0 = stdin, 1 = stdout
    mov rsi, %3         ; Address of buffer
    mov rdx, %4         ; Number of bytes to read/write
    syscall             ; Perform the system call
%endmacro

%macro exit 0
    mov rax, 60         ; Syscall number for exit
    xor rdi, rdi        ; Exit status = 0
    syscall             ; Exit the program
%endmacro

section .data
    msg1 db "Write an x86/64 ALP to accept 5 hexadecimal numbers from user and store them in an array and display the count of positive and negative numbers",10     
    msg1len equ $-msg1      ; Length of msg1

    msg2 db "Enter 5 64-bit hexadecimal numbers (0-9, A-F only):",10
    msg2len equ $-msg2      ; Length of msg2

    msg3 db "The count of positive numbers is:",10
    msg3len equ $-msg3      ; Length of msg3

    msg4 db "The count of negative numbers is:",10
    msg4len equ $-msg4      ; Length of msg4

    newline db 10           ; Line feed character

; Section: Uninitialized Data (BSS)

section .bss
    asciinum resb 17        ; Buffer to hold user input (max 16 hex chars + null)
    hexnum   resq 5         ; Space for storing 5 quadwords (64-bit numbers)
    pcount   resb 1         ; Count of positive numbers
    ncount   resb 1         ; Count of negative numbers


section .text
global _start

_start:
    ; ---- Display introductory message and prompt ----
    io 1, 1, msg1, msg1len      ; Print description and metadata
    io 1, 1, msg2, msg2len      ; Prompt for user input

    ; ---- Initialize counts to zero ----
    xor byte [pcount], 0        ; Clear positive count
    xor byte [ncount], 0        ; Clear negative count

    mov rcx, 5                  ; Loop counter for 5 inputs
    mov rsi, hexnum             ; Start address of hexnum array

; ---- Read and store 5 hexadecimal numbers ----
read_loop:
    push rcx                    ; Save loop counter
    push rsi                    ; Save current array pointer

    io 0, 0, asciinum, 17       ; Read up to 16 characters of input
    call ascii_hex64            ; Convert ASCII to 64-bit integer in RBX

    pop rsi                     ; Restore array pointer
    pop rcx                     ; Restore loop counter

    mov [rsi], rbx              ; Store converted value in array
    add rsi, 8                  ; Move pointer to next element
    loop read_loop              ; Repeat until 5 inputs are processed

    ; ---- Count positives and negatives ----
    mov rcx, 5                  ; Loop counter for 5 elements
    mov rsi, hexnum             ; Pointer to beginning of array

count_loop:
    mov rax, [rsi]              ; Load next 64-bit number
    bt rax, 63                  ; Test the sign bit (bit 63)
    jnc is_positive             ; If not set (carry = 0), it's positive
    inc byte [ncount]           ; Otherwise, increment negative count
    jmp skip_check

is_positive:
    inc byte [pcount]           ; Increment positive count

skip_check:
    add rsi, 8                  ; Move to next number in array
    loop count_loop             ; Repeat for all 5 numbers

    ; ---- Display positive count ----
    io 1, 1, msg3, msg3len      ; Print positive label
    mov bl, [pcount]            ; Load count into BL
    call hex_ascii8             ; Convert and display as 2-digit hex

    ; ---- Display negative count ----
    io 1, 1, msg4, msg4len      ; Print negative label
    mov bl, [ncount]            ; Load count into BL
    call hex_ascii8             ; Convert and display

    exit                        ; Exit the program

; hex_ascii8:
; Converts 8-bit value in BL to 2-digit hex ASCII
; Output is written to stdout
; ================================================
hex_ascii8:
    mov rsi, asciinum           ; Output buffer
    mov rcx, 2                  ; 2 hex digits for 8-bit value

conv_loop:
    rol bl, 4                   ; Rotate left to bring next nibble to low 4 bits
    mov al, bl                  ; Copy to AL
    and al, 0Fh                 ; Mask to keep only lowest nibble

    cmp al, 9
    jbe is_num
    add al, 7                   ; Adjust for 'A' - 'F'

is_num:
    add al, '0'                 ; Convert to ASCII character
    mov [rsi], al               ; Store character in buffer
    inc rsi                     ; Move to next buffer position
    loop conv_loop              ; Repeat for both nibbles

    io 1, 1, asciinum, 2        ; Print the 2-digit ASCII hex
    io 1, 1, newline, 1         ; Print newline
    ret

; ascii_hex64:
; Converts 16-character ASCII hex input from [asciinum]
; to 64-bit value stored in RBX
; ======================================================
ascii_hex64:
    mov rsi, asciinum           ; Input buffer
    xor rbx, rbx                ; Clear RBX to accumulate number
    mov rcx, 16                 ; Max of 16 hex digits (64-bit)

hex_loop:
    rol rbx, 4                  ; Shift left 4 bits (for next nibble)
    mov al, [rsi]               ; Read next input character

    cmp al, '9'
    jbe is_digit                ; '0'-'9'
    sub al, 7                   ; Adjust for 'A'-'F'

is_digit:
    sub al, '0'                 ; Convert ASCII to numeric value
    add bl, al                  ; Add digit to RBX
    inc rsi                     ; Move to next char
    loop hex_loop               ; Repeat for 16 chars
    ret
