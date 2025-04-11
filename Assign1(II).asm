; NASM x86-64 program: Accept 5 hexadecimal numbers, store in array, and print them

%macro io 4
    ; Macro to simplify Linux syscall usage
    mov rax, %1        ; Set syscall number       %1: syscall number (e.g., 0=read, 1=write, 60=exit)
    mov rdi, %2        ; Set file descriptor     %2: file descriptor (0=stdin, 1=stdout)
    mov rsi, %3        ; Set buffer address       %3: buffer address
    mov rdx, %4        ; Set buffer length       %4: length of input/output
    syscall            ; Make syscall
%endmacro

%macro exit 0
    ; Exit the program cleanly with status code 0
    mov rax, 60        ; Exit syscall number
    mov rdi,0       ; Status 0 (success)
    syscall
%endmacro

section .data
    ; Instruction and label messages
    msg1 db "accept 5 hexadecimal numbers from user and store them in an array and display the accepted numbers",10
        
    msg1len equ $ - msg1

    msg2 db "Enter 5 64-bit hexadecimal numbers (0-9, A-F only): ", 10
    msg2len equ $ - msg2

    msg3 db "5 64-bit hexadecimal numbers are: ", 10
    msg3len equ $ - msg3

    newline db 10        ; Newline character

section .bss
    asciinum resb 17     ; Buffer to read 16 hex digits + 1 newline/null
    array   resq 5      ; Reserve space for 5 unsigned 64-bit numbers

section .text
global _start

_start:
    ; Display intro and input prompt
    io 1, 1, msg1, msg1len
    io 1, 1, msg2, msg2len

    mov rcx, 5           ; Set loop counter to 5
    mov rsi, array      ; Point rsi to start of array array

read_loop:
    push rcx             ; Save loop counter
    push rsi             ; Save array pointer

    io 0, 0, asciinum, 17  ; Read hex string from user
    call ascii_hex64       ; Convert ASCII hex to binary in rbx

    pop rsi              ; Restore rsi to current array slot
    mov [rsi], rbx       ; Store converted number
    add rsi, 8           ; Move to next 64-bit slot
    pop rcx              ; Restore loop counter
    loop read_loop       ; Repeat 5 times

    io 1, 1, msg3, msg3len   ; Display output header

    mov rcx, 5           ; Set loop counter again
    mov rsi, array      ; Reset pointer to array

print_loop:
    push rcx             ; Save counter
    push rsi             ; Save pointer

    mov rbx, [rsi]       ; Load current 64-bit number
    call hex_ascii64     ; Convert and print as ASCII hex

    pop rsi              ; Restore pointer
    add rsi, 8           ; Move to next number
    pop rcx              ; Restore loop counter
    loop print_loop      ; Repeat 5 times

    exit                 ; Exit program

; -------------------------------------------
; Convert 16-digit ASCII hex string to binary
; Input: [asciinum] buffer (16 hex digits)
; Output: rbx contains the 64-bit binary number
; -------------------------------------------
ascii_hex64:
    mov rsi, asciinum    ; Start of input string
    xor rbx,0       ; Clear rbx accumulator
    mov rcx, 16          ; 16 hex characters to process

.convert_loop:
    rol rbx, 4           ; Shift 4 bits left for new nibble
    mov al, [rsi]        ; Load next ASCII character
    cmp al, '9'
    jbe .is_digit        ; If '0'-'9', jump to digit processing
    sub al, 7h           ; Adjust for 'A'-'F'
.is_digit:
    sub al, 30h          ; Convert ASCII to 0-15 value
    add bl, al           ; Merge nibble into rbx
    inc rsi              ; Move to next char
    loop .convert_loop
    ret

; -------------------------------------------
; Convert 64-bit binary number to ASCII hex
; Input: rbx = number to convert
; Output: asciinum = 16 hex digit ASCII string, printed
; -------------------------------------------
hex_ascii64:
    mov rsi, asciinum    ; Output buffer start
    mov rcx, 16          ; Convert 16 hex digits

.to_ascii_loop:
    rol rbx, 4           ; Rotate to access next nibble
    mov al, bl
    and al, 0Fh          ; Mask lower nibble
    cmp al, 9
    jbe .to_char         ; If <= 9, jump to store
    add al, 7h           ; Adjust for 'A'-'F'
.to_char:
    add al, 30h          ; Convert to ASCII
    mov [rsi], al        ; Store character
    inc rsi              ; Advance buffer pointer
    loop .to_ascii_loop

    io 1, 1, asciinum, 16 ; Print ASCII hex string
    io 1, 1, newline, 1   ; Print newline
    ret
