; Program for overlapped block transfer using string and non-string instructions

%macro io 4
    mov rax, %1              ; System call number (1 for write, 0 for read)
    mov rdi, %2              ; File descriptor (1 for stdout, 0 for stdin)
    mov rsi, %3              ; Address of buffer
    mov rdx, %4              ; Length of buffer
    syscall                  ; Perform syscall
%endmacro

%macro exit 0
    mov rax, 60              ; Exit syscall number
    xor rdi, rdi             ; Exit code 0
    syscall
%endmacro

section .data
    source dq 0x123456789ABCDEF0, 0x0FEDCBA987654321, \
            0xA1B2C3D4E5F60718, 0xFFFFFFFF00000000, \
            0x7F8E9DA1BC2D3E4F
    msg1 db "Source: ", 10
    msg2 db "Destination: ", 10
    menu db "0. Exit", 10, "1. Overlapped block transfer w/o string instructions", 10, \
             "2. Overlapped block transfer with string instructions", 10
    newline db 10
    
    menulen equ $-menu
    msg1len equ $-msg1
    msg2len equ $-msg2

section .bss
    asciinum resb 16
    choice resb 2
section .text
    global _start

_start:
    io 1, 1, menu, menulen     ; Display menu
    io 0, 0, choice, 2         ; Get user choice
    cmp byte [choice], '1'     ; Check if '1' was pressed
    je opt1                    ; Jump to option 1 if true
    cmp byte [choice], '2'     ; Check if '2' was pressed
    je opt2                    ; Jump to option 2 if true
    exit                       ; Exit if no valid choice

opt1:  ; Overlapped block transfer without string instructions
    call print_src            ; Print source block
    io 1, 1, msg2, msg2len    ; Print "Destination:" header
    mov rsi, source + 40      ; Start at last element (5th qword)
    mov rdi, source + 48      ; Destination overlaps by 1 qword
    mov rcx, 5
.copy_loop:
    mov rbx, [rsi]            ; Load qword from source
    mov [rdi], rbx            ; Store qword to destination
    sub rsi, 8                ; Move to previous element in source
    sub rdi, 8                ; Move to previous element in destination
    loop .copy_loop
    call print_dest           ; Print destination block
    exit

opt2:  ; Overlapped block transfer with string instructions
    call print_src            ; Print source block
    io 1, 1, msg2, msg2len    ; Print "Destination:" header
    mov rsi, source + 40      ; Start at last element (5th qword)
    mov rdi, source + 48      ; Destination overlaps by 1 qword
    std                       ; Set direction flag to backward (reverse)
    mov rcx, 5
    rep movsq                 ; Use string instruction to copy
    call print_dest           ; Print destination block
    exit

; Print original source block
print_src:
    io 1, 1, msg1, msg1len    ; Print "Source:" header
    mov rsi, source + 40      ; Start at last element (5th qword)
    mov rcx, 5
.src_loop:
    mov rbx, [rsi]            ; Load qword from source
    call hex_asciinum          ; Convert to ASCII hex and print it
    io 1, 1, newline, 1       ; Print newline
    sub rsi, 8                ; Move to previous element in source
    loop .src_loop            ; Repeat for 5 elements
    ret

; Print destination block after transfer
print_dest:
    mov rdi, source + 48      ; Start at destination
    mov rcx, 5
.dest_loop:
    mov rbx, [rdi]            ; Load qword from destination
    call hex_asciinum          ; Convert to ASCII hex and print it
    io 1, 1, newline, 1       ; Print newline
    sub rdi, 8                ; Move to previous element in destination
    loop .dest_loop           ; Repeat for 5 elements
    ret

; Convert 64-bit value in rbx to ASCII hexadecimal and print
hex_asciinum:
    mov rsi, asciinum          ; Address of ASCII buffer
    mov rcx, 16               ; Number of hex digits
.hex_loop:
    rol rbx, 4                ; Rotate left by 4 bits (move next nibble to LSB)
    mov al, bl                ; Move the lower 4 bits to al
    and al, 0Fh               ; Mask upper nibble
    cmp al, 9
    jbe .num                  ; If <= 9, it's a number
    add al, 7                 ; Convert to A-F for letters
.num:
    add al, 30h               ; Convert to ASCII (0-9, A-F)
    mov [rsi], al             ; Store ASCII value in buffer
    inc rsi                   ; Move to next byte in buffer
    loop .hex_loop            ; Repeat for 16 hex digits
    io 1, 1, asciinum, 16      ; Output the ASCII string
    ret
