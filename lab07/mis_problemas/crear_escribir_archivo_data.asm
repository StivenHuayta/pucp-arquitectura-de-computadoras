%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o
%define O_APPEND 2000o

section .data
    nombre_arch db "archito.txt", 0
    mensaje db "Hola desde ASM.", 10
    len equ $ - mensaje

section .text
    global _start

_start:
    mov rax, 2
    mov rdi, nombre_arch
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

escribir:
    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
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