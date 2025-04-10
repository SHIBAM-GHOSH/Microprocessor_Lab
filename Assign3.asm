; NASM x86-64 ALP to perform arithmetic operations on 64-bit hexadecimal numbers
; Macros for I/O and Exit
%macro io 4
    ; Wrapper macro for Linux I/O system calls
    mov rax,%1          ; syscall number (1=write, 0=read)
    mov rdi,%2          ; file descriptor (1=stdout, 0=stdin)
    mov rsi,%3          ; buffer address
    mov rdx,%4          ; buffer size
    syscall             ; invoke the system call
%endmacro

%macro exit 0
    ; Exit program with success status
    mov rax,60          ; syscall number for exit
    xor rdi,rdi         ; status code 0
    syscall
%endmacro

; Data Section: Messages and constants
section .data
    intro_msg db "Hexadecimal Arithmetic Operations in x86-64 NASM",10
    intro_len equ $-intro_msg

    menu db "\nMenu:",10,"0. Exit",10,"1. Add",10,"2. Subtract",10,"3. Multiply",10,"4. Divide",10
    menu_len equ $-menu

    prompt1 db "Enter first 16-digit hexadecimal number: ",10
    prompt1_len equ $-prompt1
    prompt2 db "Enter second 16-digit hexadecimal number: ",10
    prompt2_len equ $-prompt2

    sum_msg db "The sum is: ",10
    sum_len equ $-sum_msg
    carry_msg db "Carry: "
    carry_len equ $-carry_msg

    diff_msg db "The difference is: ",10
    diff_len equ $-diff_msg
    borrow_msg db "Borrow: "
    borrow_len equ $-borrow_msg

    prod_msg db "The product is: ",10
    prod_len equ $-prod_msg

    quot_msg db "Quotient: ",10
    quot_len equ $-quot_msg
    rem_msg db "Remainder: ",10
    rem_len equ $-rem_msg

    newline db 10

; BSS Section: Variables
section .bss
    choice resb 2             ; buffer to store menu choice
    asciinum resb 17          ; buffer for 16-digit hex input (plus newline)
    num1 resq 1               ; storage for first 64-bit number
    num2 resq 1               ; storage for second 64-bit number
    carry_flag resb 1         ; to indicate carry or borrow


; Code Section
section .text
global _start
_start:
    ; Show introductory message
    io 1,1,intro_msg,intro_len

main_menu:
    ; Show menu and accept user choice
    io 1,1,menu,menu_len
    io 0,0,choice,2
    cmp byte [choice],'0'
    je exit_program

    ; Read first 64-bit hexadecimal number
    io 1,1,prompt1,prompt1_len
    io 0,0,asciinum,17
    call hexstr_to_int64      ; result in rbx
    mov [num1],rbx

    ; Read second 64-bit hexadecimal number
    io 1,1,prompt2,prompt2_len
    io 0,0,asciinum,17
    call hexstr_to_int64      ; result in rbx
    mov [num2],rbx

    ; Perform operation based on user choice
    cmp byte [choice],'1'
    je add_op
    cmp byte [choice],'2'
    je sub_op
    cmp byte [choice],'3'
    je mul_op
    cmp byte [choice],'4'
    je div_op
    jmp main_menu

exit_program:
    io 1,1,newline,1
    exit

; ADDITION
; ----------------------------------
add_op:
    mov rbx,[num1]
    mov rax,[num2]
    add rbx,rax               ; result in rbx
    mov byte [carry_flag],'0'
    jnc .print                ; jump if no carry
    mov byte [carry_flag],'1'
.print:
    io 1,1,sum_msg,sum_len
    call int64_to_hexstr
    io 1,1,carry_msg,carry_len
    io 1,1,carry_flag,1
    io 1,1,newline,1
    jmp main_menu

; ----------------------------------
; SUBTRACTION
; ----------------------------------
sub_op:
    mov rbx,[num1]
    mov rax,[num2]
    sub rbx,rax               ; result in rbx
    mov byte [carry_flag],'0'
    jnc .print                ; jump if no borrow
    mov byte [carry_flag],'1'
.print:
    io 1,1,diff_msg,diff_len
    call int64_to_hexstr
    io 1,1,borrow_msg,borrow_len
    io 1,1,carry_flag,1
    io 1,1,newline,1
    jmp main_menu

; ----------------------------------
; MULTIPLICATION
mul_op:
    mov rax,[num1]
    mul qword [num2]         ; rdx:rax = result
    push rdx
    push rax
    io 1,1,prod_msg,prod_len
    pop rbx
    call int64_to_hexstr     ; print lower 64 bits
    pop rbx
    call int64_to_hexstr     ; print upper 64 bits
    io 1,1,newline,1
    jmp main_menu

; ----------------------------------
; DIVISION
div_op:
    mov rax,[num1]
    xor rdx,rdx              ; clear remainder
    div qword [num2]         ; quotient in rax, remainder in rdx
    mov rbx,rax
    io 1,1,quot_msg,quot_len
    call int64_to_hexstr
    mov rbx,rdx
    io 1,1,rem_msg,rem_len
    call int64_to_hexstr
    io 1,1,newline,1
    jmp main_menu

; ----------------------------------
; Convert 16-digit hex string to 64-bit integer in RBX
hexstr_to_int64:
    mov rsi,asciinum         ; pointer to input string
    xor rbx,rbx              ; clear result register
    mov rcx,16               ; loop for 16 characters
.loop:
    mov al,[rsi]             ; get character
    rol rbx,4                ; shift previous value 4 bits left
    cmp al,'9'
    jbe .digit               ; if <= '9'
    sub al,7h                ; adjust for A-F
.digit:
    sub al,30h               ; convert ASCII to binary
    add bl,al
    inc rsi
    loop .loop
    ret

; ----------------------------------
; Convert 64-bit integer in RBX to 16-digit hex string
int64_to_hexstr:
    mov rsi,asciinum         ; pointer to output string
    mov rcx,16               ; loop 16 times
.loop:
    rol rbx,4                ; rotate left by 4 bits
    mov al,bl
    and al,0Fh               ; isolate last 4 bits
    cmp al,9
    jbe .digit
    add al,7h                ; convert 10-15 to A-F
.digit:
    add al,30h               ; convert to ASCII character
    mov [rsi],al
    inc rsi
    loop .loop
    io 1,1,asciinum,16       ; print 16-digit hex string
    ret
