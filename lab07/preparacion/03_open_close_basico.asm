; =============================================================================
; Plantilla: Abrir y cerrar un archivo fijo ("archivo.txt") en modo lectura
; Compilar:  nasm -f elf64 03_open_close_basico.asm && ld 03_open_close_basico.o -o exe
; Uso:       ./exe   (requiere que archivo.txt exista)
; =============================================================================

%define O_RDONLY 0              ; flag de solo lectura (Linux x86-64)

section .data
    filename db "archivo.txt", 0 ; nombre del archivo terminado en '\0'

section .text
    global _start

_start:
    ; 1. Abrir archivo existente en solo lectura: sys_open(filename, O_RDONLY, 0)
    mov rax, 2                  ; syscall sys_open
    mov rdi, filename           ; puntero al nombre del archivo
    mov rsi, O_RDONLY           ; solo lectura
    mov rdx, 0                  ; modo en 0 (solo se usa al crear archivos)
    syscall

    cmp rax, 0                  ; si rax < 0, ocurrió un error (ej. no existe)
    jl salida_error

    mov rbx, rax                ; guardar file descriptor (fd) en rbx

    ; 2. Cerrar el archivo: sys_close(fd)
    mov rax, 3                  ; syscall sys_close
    mov rdi, rbx                ; rdi = fd del archivo
    syscall

    ; 3. Salir sin errores: sys_exit(0)
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0
    syscall

salida_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall