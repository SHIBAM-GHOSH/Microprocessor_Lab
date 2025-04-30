; === Macros for write and read system calls ===
%macro write 2
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor 1 (stdout)
    mov rsi, %1             ; address of message
    mov rdx, %2             ; message length
    syscall
%endmacro

%macro read 2
    mov rax, 0              ; syscall: sys_read
    mov rdi, 0              ; file descriptor 0 (stdin)
    mov rsi, %1             ; input B_result
    mov rdx, %2             ; input length
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

    endl db 10              ; newline character

; === Uninitialized data (variables) ===
section .bss
    choice resb 2           ; store user menu choice
    hex_input resb 5        ; 4-digit ASCII hex STRING + newline (read 5 bytes)
    bcd_input resb 6        ; 5-digit decimal  BCD + newline
    B_result resb 5           ; temp B_result to hold BCD characters
    H_result resb 4           ; final hex H_result (4 characters)

; === Code Section ===
section .text
    global _start

_start:
    write msg_intro, intro_len     ; Display introduction message

main_menu:
    write msg_menu, menu_len       ; Show the menu
    read choice, 2                 ; Read user's menu choice (1 character + newline)

    cmp byte [choice], '1'
    je hex_to_bcd                  ; If choice is 1 → Hex to BCD

    cmp byte [choice], '2'           ; je- jump is equal
    je bcd_to_hex                  ; If choice is 2 → BCD to Hex

    cmp byte [choice], '3'
    je exit_program                ; If choice is 3 → Exit

    jmp main_menu                  ; Invalid input, redisplay menu

; === Option 1: Convert 4-digit Hex to BCD ===
hex_to_bcd:
    write msg_input, inplen        ; Prompt user for hex input
    read hex_input, 5              ; Read 4-digi=t hex input + newline

    call asciihex_bin              ; Convert ASCII hex string to binary, result in BX

    mov ax, bx                     ; Move binary value from BX to AX for division
    mov bx, 10                     ; Divisor: 10 (base 10)
    mov rcx, 5                     ; We will extract 5 decimal digits
    mov rsi, B_result + 4          ; Point to the last byte in B_result buffer
                                   ; We’ll store digits from right to left
reverse_store_loop:
    mov rdx, 0                     ; Clear remainder register before division
    div bx                         ; AX ÷ 10 → Quotient in AX, remainder in DX
    add dl, '0'                    ; Convert binary remainder to ASCII
    mov [rsi], dl                  ; Store ASCII digit in current position
    dec rsi                        ; Move left for next digit
    loop reverse_store_loop        ; Repeat for all 5 digits

    mov rsi, B_result              ; Reset rsi to point to start of result string
    write B_result, 5              ; Display the 5-digit BCD result
    write endl, 1                  ; Print newline
    jmp main_menu                  ; Go back to main menu


; === Option 2: Convert 5-digit BCD to Hex ===
bcd_to_hex:
    write msg_input, inplen      ; Prompt user for BCD input
    read bcd_input, 6            ; take 5 digit ascii input of bcd decimal No.

    mov rsi, bcd_input           ; Pointer to input string
    mov rcx, 5                   ; 5 digits to process
    mov rax, 0                   ; Final result will be in AX (via RAX)
    mov bx, 10                   ; Base 10

bcd_loop:
    mul bx                       ; RAX *= 10
    mov dl, [rsi]                ; Read next ASCII digit,  like = 6179
    sub dl, '0'                  ; Convert ASCII charac.  to binary form
    add al, dl                   ; Add to result(store in ascii as binary in rax)
    inc rsi
    loop bcd_loop

    mov bx, ax                   ; Move result to BX for HexBin_Ascii conversion
    call Hexbin_Ascii           ; Convert binary to ASCII hex string, result stored in H_result variable
    write H_result, 4              ; Display hex string
    write endl, 1
    jmp main_menu

; === Exit program ===
exit_program:
    mov rax, 60                  ; syscall: exit
    mov rdi, 0                ; return code 0
    syscall

; === Helper: Convert 4-digit ASCII hex to binary in BX ===
asciihex_bin:
    mov bx, 0                    ; Clear BX to accumulate result
    mov rsi, hex_input           ; Pointer to input
    mov rcx, 4                   ; 4 hex digits to process

ascii_loop:
    rol bx, 4                    ; Left shift BX by 4 bits to make space
    mov al, [rsi]                ; Load ASCII character
    cmp al, '9'
    jbe is_digit                 ; If <= '9', it's a digit
    sub al, 7h                   ; Adjust for 'A'-'F' (e.g., 'A' → 10)
is_digit:
    sub al, '0'                  ; Convert ASCII to bin number or decimal 
    add bl, al                   ; Add digit to BX (every hex element is convertd to 4 bit binary)
    inc rsi                      ; like "1A3"  =  0001 1010 0011 in BX 
    loop ascii_loop
    ret

; === Helper: Convert binary in BX to 4-digit ASCII hex string ===
Hexbin_Ascii:
    mov rsi, H_result              ; H_result pointer
    mov rcx, 4                   ; 4 hex digits to print

hex_loop:
    rol bx, 4                    ; Rotate left to get next nibble in low 4 bits
    mov al, bl                   ; Get current nibble
    and al, 0Fh                  ; Mask lower 4 bits
    cmp al, 9
    jbe hex_digit                ; If <= 9, it's a digit
    add al, 7h                   ; Adjust for A–F
hex_digit:
    add al, '0'                  ; Convert to ASCII
    mov [rsi], al               ; Store character
    inc rsi
    loop hex_loop
    ret
