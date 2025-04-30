%macro io 4
    mov rax, %1        ; rax = syscall number (1 = write, 0 = read)
    mov rdi, %2        ; rdi = file descriptor (1 = stdout, 0 = stdin)
    mov rsi, %3        ; rsi = address of buffer
    mov rdx, %4        ; rdx = number of bytes to read/write
    syscall            ; invoke Linux kernel
%endmacro

%macro exit 0
    mov rax, 60        ; syscall number for exit
    xor rdi, rdi       ; rdi = exit code (0)
    syscall            ; invoke syscall
%endmacro

section .data
    ; 5 sample 64-bit values (source array)
    source dq 0x123456789ABCDEF0, 0x0FEDCBA987654321, 0xA1B2C3D4E5F60718
           dq 0xFFFFFFFF00000000, 0x7F8E9DA1BC2D3E4F

    dest dq 0, 0, 0, 0, 0    ; Destination array initialized to zero

    msg1 db "Source: ", 10         ; Message header for source display
    msg1len equ $ - msg1           ; Length of msg1

    msg2 db "Destination: ", 10    ; Message header for destination display
    msg2len equ $ - msg2           ; Length of msg2

    newline db 10                  ; Line break
    arrow db "  --->   "           ; Used for formatting
    arrowlen equ $ - arrow

section .bss
    ascii64 resb 16    ; Buffer for 16 hex characters (64 bits = 16 hex digits)

section .text
    global _start

_start:
    ; Display menu for selecting block transfer option
    io 1, 1, "Select Block Transfer Mode (1 for non-overlapped without string, 2 for non-overlapped with string):", 85
    io 0, 0, ascii64, 2  ; Get user input for selection (1 or 2)

    cmp byte [ascii64], '1'    ; If user selects '1'
    je non_overlapped_no_str

    cmp byte [ascii64], '2'    ; If user selects '2'
    je non_overlapped_with_str

    exit  ; Exit program if invalid input

; Non-overlapped Block Transfer Without String Instructions
non_overlapped_no_str:
    call print_src

    ; Setup for non-overlapped transfer (without string instructions)
    mov rsi, source     ; rsi = pointer to source array
    mov rdi, dest       ; rdi = pointer to destination array
    mov rcx, 5          ; Copy 5 elements (5 qwords)
.copy_no_str:
    mov rbx, [rsi]      ; Load 64-bit value from source into rbx
    mov [rdi], rbx      ; Store it into destination
    add rsi, 8          ; Move to next source element (8 bytes = 64 bits)
    add rdi, 8          ; Move to next destination element
    loop .copy_no_str   ; Repeat 5 times

    call print_dest
    exit

; Non-overlapped Block Transfer With String Instructions
non_overlapped_with_str:
    call print_src

    ; Setup for non-overlapped transfer using string instructions
    mov rsi, source     ; rsi = pointer to source array
    mov rdi, dest       ; rdi = pointer to destination array
    mov rcx, 5          ; Copy 5 elements (5 qwords)
    rep movsq           ; Use rep movsq to copy 5 qwords , movsq
;movsq: This is a string instruction that moves a 64-bit value (8 bytes) from the source (pointed to by rsi) 
;to the destination (pointed to by rdi).
;movsq stands for Move Quadword (64-bit).
;After each transfer, the rsi and rdi registers are automatically incremented by 8 bytes (the size of one 64-bit value).
; This means the next 64-bit value will be copied in the next iteration.
    call print_dest
    exit

; Print Source Block
print_src:
    io 1, 1, msg1, msg1len     ; Print "Source:" header
    mov rsi, source            ; rsi = pointer to source array
    mov rcx, 5                 ; Print 5 elements
.src_loop:
    mov rbx, rsi             ; Load address of block from source
    call hex_ascii64           ; Convert address to hex and print it
    io 1, 1, arrow, arrowlen   ; Print arrow "  --->   "
    mov rbx, [rsi]             ; Load 64-bit value from memory
    call hex_ascii64           ; Convert value to ASCII hex and print it
    io 1, 1, newline, 1        ; Print newline
    add rsi, 8                 ; Move to next 64-bit value
    loop .src_loop             ; Repeat loop for 5 elements
    ret

; Print Destination Block
print_dest:
    io 1, 1, msg2, msg2len     ; Print "Destination:" header
    mov rsi, dest              ; rsi = pointer to destination array
    mov rcx, 5                 ; Print 5 elements
.dest_loop:
    mov rbx, [rsi]             ; Load 64-bit value from destination
    call hex_ascii64           ; Convert to ASCII hex and print it
    io 1, 1, newline, 1        ; Print newline
    add rsi, 8                 ; Move to next 64-bit value
    loop .dest_loop            ; Repeat loop for 5 elements
    ret

; Convert RBX to 16-digit hex and print
hex_ascii64:
    mov rsi, ascii64           ; rsi points to output buffer
    mov rcx, 16                ; Loop 16 times (16 hex digits for 64-bit)

.hex_loop:
    rol rbx, 4                 ; Rotate left by 4 bits (move next nibble into LSB)
    mov al, bl                 ; Get lower 8 bits (now contains the nibble)
    and al, 0Fh                ; Mask only the lowest 4 bits
    add al, '0'                ; Convert 0–9 to ASCII
    cmp al, '9'
    jbe .store                 ; If <= '9', skip A-F conversion
    add al, 7                  ; Else convert to 'A'-'F'

.store:
    mov [rsi], al              ; Store ASCII character into buffer
    inc rsi                    ; Move to next byte in buffer
    loop .hex_loop             ; Do it for 16 nibbles

    io 1, 1, ascii64, 16       ; Print the final ASCII string
    ret
