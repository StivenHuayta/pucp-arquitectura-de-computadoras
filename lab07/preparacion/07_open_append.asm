; =============================================================================
; Plantilla: Abrir/crear archivo ("log.txt") y agregar texto al final (O_APPEND)
; Compilar:  nasm -f elf64 07_open_append.asm && ld 07_open_append.o -o exe
; Uso:       ./exe
; =============================================================================

%define O_WRONLY 1
%define O_CREAT  100o
%define O_APPEND 2000o

section .data:
    filename db "log.txt", 0
    mensaje db "Línea agregada desde ASM.", 10
    len equ $ - mensaje

section .text
    global _start

_start:
    mov rax, 2                              ; open
    mov rdi, filename
    mov rsi, O_WRONLY | O_CREAT | O_APPEND
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salida_error

    mov rbx, rax

    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

salida_error:
    mov rax, 60
    mov rdi, 1
    syscall