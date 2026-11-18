%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o
%define O_APPEND 2000o

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 3
    jne salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rsi, [rsp + 24]
    xor rdx, rdx

contar:
    cmp byte [rsi + rdx], 0
    je escribir
    inc rdx
    jmp contar

escribir:
    mov rax, 1
    mov rdi, rbx
    syscall

cerrar:
    mov rax, 3
    mov rdi, rbx
    syscall

salir:
    mov rax, 60
    xor rdi, rdi
    syscall

salir_error:
    mov rax, 60
    mov rdi, 0xFF
    syscall