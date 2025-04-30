%include "macro.asm"  ; Include file with macros for Print, Accept, fopen, fcreate, fread, fclose, fdelete, etc.

section .data
    ; Introductory message
    intro_msg db 10, "Write X86/64 ALP to implement TYPE, COPY, DELETE using file operations", 10
    intro_len equ $ - intro_msg

    ; Menu message
    msg db "------------------MENU------------------", 10 
        db "1. TYPE ", 10 
        db "2. COPY ", 10 
        db "3. DELETE ", 10 
        db "4. Exit ", 10
        db "Enter your choice : "
    msglen equ $ - msg

    endl db 10              ; Newline character
    m db "DONE!", 10        ; Generic done message

section .bss
    choice resb 2           ; User input for menu choice
    fname_source resb 50    ; Source file name (used in TYPE and COPY)
    fname_dest resb 50      ; Destination file name (used in COPY and DELETE)
    filehandle_src resq 1   ; File descriptor for source file
    filehandle_dest resq 1  ; File descriptor for destination file
    buffer resb 100         ; Buffer to store file contents
    bufferlen resq 1        ; Number of bytes read/written

section .text
global _start

; -------------------- PROGRAM ENTRY POINT --------------------
_start:
    ; Command-line arguments setup
    pop rbx                 ; argc - number of arguments (ignored)
    pop rsi                 ; skip program name from argv

    ; Print welcome/introduction message
    Print intro_msg, intro_len

    ; Read first argument (source file name) into fname_source
    mov rdi, fname_source
.read_args:
    pop rsi                 ; Get next argument from stack
    mov rdx, 0              ; Offset counter for copying
.copy_chars:
    mov al, byte [rsi + rdx]    ; Copy byte from arg
    mov [rdi + rdx], al         ; Store in destination buffer
    cmp al, 0                   ; Check for end of string
    je .next_arg
    inc rdx
    jmp .copy_chars

.next_arg:
    cmp rdi, fname_dest         ; Already filled dest? Proceed to menu
    je show_menu
    mov rdi, fname_dest         ; Now copy next arg into fname_dest
    jmp .read_args

; -------------------- DISPLAY MENU --------------------
show_menu:
    Print msg, msglen       ; Print the menu
    Accept choice, 2        ; Get user choice as input (1 character expected)

    ; Check user's menu selection and jump to corresponding handler
    cmp byte [choice], '1'
    je handle_type

    cmp byte [choice], '2'
    je handle_copy

    cmp byte [choice], '3'
    je handle_delete

    cmp byte [choice], '4'
    je exit_program

    ; Invalid input → show menu again
    jmp show_menu

; -------------------- CASE 1: TYPE FILE --------------------
handle_type:
    fopen fname_source              ; Open source file in read mode
    cmp rax, -1                     ; Check if open failed
    je exit_program
    mov [filehandle_src], rax      ; Save file descriptor

    fread [filehandle_src], buffer, 100  ; Read up to 100 bytes
    mov [bufferlen], rax           ; Save number of bytes read

    Print endl, 1                  ; Print newline for formatting
    Print buffer, [bufferlen]      ; Display contents of buffer

    fclose [filehandle_src]        ; Close file after reading
    jmp show_menu

; -------------------- CASE 2: COPY FILE --------------------
handle_copy:
    fopen fname_source              ; Open source file in read mode
    cmp rax, -1
    je exit_program
    mov [filehandle_src], rax

    fcreate fname_dest             ; Create destination file
    cmp rax, -1
    je exit_program
    mov [filehandle_dest], rax

.copy_loop:
    fread [filehandle_src], buffer, 100  ; Read 100 bytes
    cmp rax, 0                           ; If 0, EOF reached
    je .copy_done

    ; Write contents to destination using syscall (manual write)
    mov rdi, [filehandle_dest]     ; fd
    mov rsi, buffer                ; buffer address
    mov rdx, rax                   ; number of bytes to write
    mov rax, 1                     ; syscall: write
    syscall
    jmp .copy_loop

.copy_done:
    fclose [filehandle_src]
    fclose [filehandle_dest]
    Print m, 6                     ; Print DONE!
    jmp show_menu

; -------------------- CASE 3: DELETE FILE --------------------
handle_delete:
    fdelete fname_dest             ; Delete the file specified in second argument
    Print m, 6                     ; Confirm deletion with DONE!
    jmp show_menu

; -------------------- CASE 4: EXIT --------------------
exit_program:
    mov rax, 60        ; syscall: exit
    xor rdi, rdi       ; return code = 0
    syscall
