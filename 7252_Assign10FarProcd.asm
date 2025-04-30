%include "macro.asm" ; Include macros for printing

section .data
    msg_space db "Number of spaces: ", 0
    msg_space_len equ $ - msg_space

    msg_line db "Number of lines: ", 0
    msg_line_len equ $ - msg_line

    msg_char db "Number of occurrences of character: ", 0
    msg_char_len equ $ - msg_char

    dispbuff db 0, 0      ; Buffer for 2-digit display
    nl db 10              ; Newline character

section .bss
    space_count resb 1    ; Count of blank spaces (0x20)
    line_count  resb 1    ; Count of newline characters (0x0A)
    char_count  resb 1    ; Count of specific character

section .text
global analyze_text        ; Make procedure publicly available
extern buffer, buf_len, character  ; External symbols (defined in main file)

; FAR PROCEDURE to process buffer and count characters
analyze_text:
    xor rcx, rcx           ; Clear loop counter
    xor rbx, rbx           ; Clear general-purpose register
    xor rdx, rdx           ; Clear data register

    mov rsi, buffer        ; RSI points to the start of buffer
    mov rcx, [buf_len]     ; Total number of characters to process
    mov bl, byte [character] ; Character to be searched

.process_loop:
    cmp rcx, 0             ; Loop until all bytes are read
    je .display_counts

    mov al, [rsi]          ; Load current character

    ; Check for blank space (ASCII 0x20)
    cmp al, 0x20
    jne .check_newline
    inc byte [space_count]

.check_newline:
    ; Check for newline (ASCII 0x0A)
    cmp al, 0x0A
    jne .check_target_char
    inc byte [line_count]

.check_target_char:
    ; Check for specific character match
    cmp al, bl
    jne .next_char
    inc byte [char_count]

.next_char:
    inc rsi                ; Move to next character in buffer
    dec rcx                ; Decrement counter
    jmp .process_loop

; Display all results
.display_counts:
    ; Show number of spaces
    Print msg_space, msg_space_len
    mov bl, [space_count]
    call print_byte_as_hex

    ; Show number of lines
    Print msg_line, msg_line_len
    mov bl, [line_count]
    call print_byte_as_hex

    ; Show number of specific character
    Print msg_char, msg_char_len
    mov bl, [char_count]
    call print_byte_as_hex

    ret

; Display byte value in 2-digit hexadecimal format
print_byte_as_hex:
    mov rsi, dispbuff
    mov rcx, 2

.convert_loop:
    rol bl, 4              ; Rotate left to bring next nibble to low 4 bits
    mov al, bl
    and al, 0x0F           ; Mask high nibble

    cmp al, 9              ; Convert nibble to ASCII
    jbe .to_digit
    add al, 0x37           ; A-F (10-15) → 'A'-'F'
    jmp .store_char

.to_digit:
    add al, 0x30           ; 0-9 → '0'-'9'

.store_char:
    mov [rsi], al          ; Store ASCII character
    inc rsi
    loop .convert_loop

    Print dispbuff, 2      ; Print 2-digit value
    Print nl, 1            ; New line
    ret
