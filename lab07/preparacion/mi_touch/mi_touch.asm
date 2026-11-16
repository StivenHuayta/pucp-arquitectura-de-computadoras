%define O_WRONLY 1
%define O_CREAT 100o

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_WRONLY | O_CREAT
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall    