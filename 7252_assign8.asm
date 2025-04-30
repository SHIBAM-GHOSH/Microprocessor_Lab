; Name: Uday Pratap Singh
; Roll No: 7259
; Date: 3 April, 2025

; Program to multiply two 8-bit hex numbers using:
;   - Successive Addition
;   - Shift and Add method
; Written in NASM for x86_64 Linux platform

section .data
    msg1 db "Enter first 8-bit hex number (2 digits): ", 10       ; Prompt for first number
    msg1len equ $ - msg1
    msg2 db "Enter second 8-bit hex number (2 digits): ", 10      ; Prompt for second number
    msg2len equ $ - msg2
    msg3 db "Result (Successive Addition): ", 10                  ; Label for first method result
    msg3len equ $ - msg3
    msg4 db "Result (Shift and Add): ", 10                        ; Label for second method result
    msg4len equ $ - msg4
    dispbuff db 4 dup(0)                                          ; Buffer to store and print 4-digit hex result
    newline db 10                                                ; Newline character

section .bss
    ascii_num resb 3           ; Buffer for user input (2 hex digits + newline)
    num1 resb 1                ; Storage for first number
    num2 resb 1                ; Storage for second number

; Macro to print messages using syscall write
%macro PRINT 2
    mov rax, 1                ; syscall number for write
    mov rdi, 1                ; file descriptor 1 = stdout
    mov rsi, %1              ; buffer to print
    mov rdx, %2              ; length of buffer
    syscall                  ; execute syscall
%endmacro

; Macro to accept user input using syscall read
%macro ACCEPT 2
    mov rax, 0                ; syscall number for read
    mov rdi, 0                ; file descriptor 0 = stdin
    mov rsi, %1              ; input buffer
    mov rdx, %2              ; length to read
    syscall                  ; execute syscall
%endmacro

section .text
    global _start

_start:
    ; Prompt and get first 8-bit hex number
    PRINT msg1, msg1len
    ACCEPT ascii_num, 3           ; Read 2 digits and newline from user
    call Convert_Ascii_To_Hex     ; Convert ASCII to hex
    mov [num1], bl                ; Store converted number in num1

    ; Prompt and get second 8-bit hex number
    PRINT msg2, msg2len
    ACCEPT ascii_num, 3           ; Read 2 digits and newline
    call Convert_Ascii_To_Hex     ; Convert ASCII to hex
    mov [num2], bl                ; Store converted number in num2

    ; Multiply using Successive Addition
    call Multiply_Successive_Add
    PRINT msg3, msg3len           ; Label output
    PRINT dispbuff, 4             ; Display result buffer
    PRINT newline, 1              ; Print newline

    ; Multiply using Shift and Add method
    call Multiply_Shift_Add
    PRINT msg4, msg4len           ; Label output
    PRINT dispbuff, 4             ; Display result buffer
    PRINT newline, 1              ; Newline for formatting

    ; Exit the program
    mov rax, 60                   ; syscall number for exit
    mov rdi, 0                    ; exit code 0
    syscall

; -----------------------------------------------------
; Multiply using successive addition method
; Repeatedly add the first number as many times as the second number
Multiply_Successive_Add:
    xor rax, rax                  ; Clear RAX to prepare for result
    xor rbx, rbx                  ; Clear RBX where result will accumulate
    xor rcx, rcx                  ; Clear RCX (counter)
    mov al, [num1]                ; Load first number into AL
    mov cl, [num2]                ; Load second number into CL (loop counter)

.add_loop:
    test rcx, rcx                 ; Check if counter is zero
    jz .done_succ_add             ; If zero, we're done
    add bx, ax                    ; Add AX to BX (accumulate partial sum)
    dec rcx                       ; Decrement counter
    jmp .add_loop                 ; Repeat until counter reaches 0

.done_succ_add:
    call Convert_Hex_To_Ascii     ; Convert final result to ASCII for display
    ret

; -----------------------------------------------------
; Multiply using shift and add method
; Check each bit of the multiplier (BL), if set, add multiplicand (AX)
Multiply_Shift_Add:
    xor rcx, rcx                  ; Clear RCX (will store final result)
    xor rax, rax                  ; Clear RAX
    xor rbx, rbx                  ; Clear RBX
    mov dx, 8                     ; Set bit counter for 8-bit multiplier
    mov al, [num1]                ; Load first number (multiplicand) into AL
    mov bl, [num2]                ; Load second number (multiplier) into BL

.shift_loop:
    test dx, dx                   ; If counter reaches 0, stop
    jz .done_shift_add
    shr bl, 1                     ; Shift BL right (check least significant bit)
    jnc .no_add                   ; If carry not set, skip addition
    add cx, ax                    ; If carry set, add AX to CX (partial product)

.no_add:
    shl ax, 1                     ; Shift AX left (prepare next multiple of multiplicand)
    dec dx                        ; Decrease bit counter
    jmp .shift_loop               ; Repeat

.done_shift_add:
    mov bx, cx                    ; Move result to BX for display
    call Convert_Hex_To_Ascii     ; Convert result to ASCII
    ret

; -----------------------------------------------------
; Convert 16-bit hex in BX to 4-digit ASCII hex in dispbuff
Convert_Hex_To_Ascii:
    mov rsi, dispbuff             ; Buffer to store result
    mov rcx, 4                    ; We want 4 hex digits

.hex_to_ascii_loop:
    rol bx, 4                     ; Rotate left to get next nibble in lower 4 bits
    mov al, bl                    ; Load low nibble into AL
    and al, 0Fh                   ; Mask upper 4 bits
    cmp al, 9
    jbe .digit                    ; If <= 9, it's 0-9
    add al, 7                     ; Else add 7 (convert to A-F)

.digit:
    add al, 30h                   ; Convert 0-9, A-F to ASCII characters
    mov [rsi], al                 ; Store ASCII character in buffer
    inc rsi                       ; Move to next byte
    dec rcx                       ; Decrement count
    jnz .hex_to_ascii_loop        ; Repeat until 4 digits done
    ret

; -----------------------------------------------------
; Convert 2-digit ASCII hex to binary in BL
Convert_Ascii_To_Hex:
    mov rsi, ascii_num            ; Point to input buffer
    mov rcx, 2                    ; Two digits to process
    xor bl, bl                    ; Clear BL (result byte)

.ascii_to_hex_loop:
    rol bl, 4                     ; Make room for next nibble
    mov al, [rsi]                 ; Read one character from input
    cmp al, '9'                   ; Check if it's a digit
    jbe .is_digit
    sub al, 37h                   ; For A-F: 'A' (41h) - 37h = 0Ah
    jmp .combine

.is_digit:
    sub al, 30h                   ; For digits: '0' = 30h -> 0

.combine:
    add bl, al                    ; Add digit to BL
    inc rsi                       ; Move to next input character
    dec rcx                       ; One less digit to convert
    jnz .ascii_to_hex_loop        ; Repeat for 2 digits
    ret