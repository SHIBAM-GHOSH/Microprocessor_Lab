section .data
    msg db "Hello, World!", 10     ; Message with newline
    msglen equ $ - msg             ; Calculate message length

section .text
    global _start

_start:
    ; syscall: write(1, msg, msglen)
    mov rax, 1          ; syscall number for write
    mov rdi, 1          ; file descriptor 1 = stdout
    mov rsi, msg        ; address of the message
    mov rdx, msglen     ; length of the message
    syscall

    ; syscall: exit(0)
    mov rax, 60         ; syscall number for exit
    xor rdi, rdi        ; exit code 0
    syscall
