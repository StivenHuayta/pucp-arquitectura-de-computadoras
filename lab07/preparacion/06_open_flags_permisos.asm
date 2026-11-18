; =============================================================================
; Plantilla: Uso de flags (O_WRONLY | O_CREAT | O_TRUNC) y permisos (644o) en open
; Compilar:  nasm -f elf64 06_open_flags_permisos.asm && ld 06_open_flags_permisos.o -o exe
; Uso:       ./exe   (crea/sobrescribe "salida.txt")
; =============================================================================

%define O_WRONLY 1
%define O_CREAT 100o
%define O_TRUNC 1000o

section .data
    filename db "salida.txt", 0
    mensaje db "Nuevo contenido desde ASM.", 10
    len equ $ - mensaje

section .text
    global _start

_start:
    mov rax, 2                              ; syscall open
    mov rdi, filename                       ; nombre del archivo
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC   ; flags de apertura
    mov rdx, 644o                           ; permisos si se crea el archivo
    syscall

    cmp rax, 0
    jl salida_error

    mov rbx, rax                            ; salvo el fd devuelto

    mov rax, 1                              ; syscall write
    mov rdi, rbx                            ; fd
    mov rsi, mensaje                        ; cadena a escribir
    mov rdx, len                            ; tamaño de la cadena
    syscall                         

    mov rax, 3                              ; close
    mov rdi, rbx                            ; fd
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

salida_error:
    mov rax, 60
    mov rdi, 1
    syscall