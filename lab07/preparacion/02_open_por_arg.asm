; =============================================================================
; Plantilla: Abrir un archivo recibido por argumento (O_RDONLY) y cerrarlo
; Compilar:  nasm -f elf64 02_open_por_arg.asm && ld 02_open_por_arg.o -o exe
; Uso:       ./exe <archivo>
; =============================================================================

%define O_RDONLY 0

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    xor rdi, rbx
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall