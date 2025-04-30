%include "macro.asm"  ; Include your custom macros (for Print/Accept, etc.)

section .data
    intro_msg db "Write X86 ALP to find:", 10, \
                 "a) Number of Blank spaces", 10, \
                 "b) Number of lines", 10, \
                 "c) Occurrence of a particular character.", 10
    intro_len equ $ - intro_msg

    msg1 db "Enter file name: ", 0
    msg1len equ $ - msg1

    msg2 db "Enter character to search: ", 0
    msg2len equ $ - msg2

    error_msg db "Error in Opening File", 10
    error_len equ $ - error_msg

section .bss
    global buffer          ; Accessible by far procedure
    global buf_len         ; Accessible by far procedure
    global character       ; Accessible by far procedure

    filename    resb 100   ; For storing file name input
    character   resb 2     ; Input character to search (null-terminated)
    buffer      resb 1024  ; Buffer to hold file content
    buf_len     resq 1     ; Will store how many bytes read
    filehandle  resq 1     ; Holds file descriptor

section .text
    global _start
    extern far_procedure   ; FAR procedure from Program_2

_start:
    ; --- Display assignment intro ---
    Print intro_msg, intro_len

    ; --- Prompt user for file name ---
    Print msg1, msg1len
    Accept filename, 100

    ; --- Strip newline character after filename ---
    mov rsi, filename
.find_newline:
    mov al, [rsi]
    cmp al, 10             ; Newline character
    je .null_terminate
    cmp al, 0              ; End of string
    je .after_filename
    inc rsi
    jmp .find_newline

.null_terminate:
    mov byte [rsi], 0      ; Replace newline with null terminator
.after_filename:

    ; --- Prompt user for the character to search ---
    Print msg2, msg2len
    Accept character, 2
    mov byte [character+1], 0  ; Null-terminate the input

    ; --- Open the file (syscall: open) ---
    mov rax, 2             ; syscall: open
    mov rdi, filename      ; pointer to filename
    mov rsi, 0             ; read-only
    syscall

    cmp rax, -1
    je open_error          ; If failed, show error
    mov [filehandle], rax  ; Save file handle

    ; --- Read file contents into buffer ---
    mov rdi, [filehandle]  ; file descriptor
    mov rax, 0             ; syscall: read
    mov rsi, buffer        ; buffer to store data
    mov rdx, 1024          ; max bytes to read
    syscall
    mov [buf_len], rax     ; Save number of bytes read

    ; --- Close the file (syscall: close) ---
    mov rax, 3
    mov rdi, [filehandle]
    syscall

    ; --- Call FAR procedure (Program_2) ---
    call far_procedure

    ; --- Exit the program (syscall: exit) ---
    mov rax, 60
    xor rdi, rdi
    syscall

; --- Error handler if file can't be opened ---
open_error:
    Print error_msg, error_len
    mov rax, 60
    mov rdi, 1             ; exit with code 1
    syscall
