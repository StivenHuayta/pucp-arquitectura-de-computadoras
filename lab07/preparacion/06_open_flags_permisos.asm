; =============================================================================
; Plantilla: Uso de flags (O_WRONLY | O_CREAT | O_TRUNC) y permisos (644o) en open
; Compilar:  nasm -f elf64 06_open_flags_permisos.asm && ld 06_open_flags_permisos.o -o exe
; Uso:       ./exe   (crea/sobrescribe "salida.txt")
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe

section .data
    filename db "salida.txt", 0                 ; nombre del archivo terminado en '\0'
    mensaje  db "Nuevo contenido desde ASM.", 10 ; texto a escribir con '\n'
    len      equ $ - mensaje                    ; longitud del mensaje en bytes

section .text
    global _start

_start:
    ; 1. Abrir o crear el archivo: sys_open(filename, flags, 644o)
    mov rax, 2                              ; syscall sys_open
    mov rdi, filename                       ; nombre del archivo
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC   ; escritura + crear + sobrescribir
    mov rdx, 644o                           ; permisos rw-r--r-- si se crea
    syscall

    cmp rax, 0                              ; si rax < 0, ocurrió un error
    jl salida_error

    mov rbx, rax                            ; guardar file descriptor (fd) en rbx

    ; 2. Escribir el mensaje: sys_write(fd, mensaje, len)
    mov rax, 1                              ; syscall sys_write
    mov rdi, rbx                            ; rdi = fd del archivo
    mov rsi, mensaje                        ; buffer a escribir
    mov rdx, len                            ; cantidad de bytes
    syscall

    ; 3. Cerrar el archivo: sys_close(fd)
    mov rax, 3                              ; syscall sys_close
    mov rdi, rbx                            ; rdi = fd del archivo
    syscall

    ; 4. Salir sin errores: sys_exit(0)
    mov rax, 60                             ; syscall sys_exit
    xor rdi, rdi                            ; código de salida 0
    syscall

salida_error:
    mov rax, 60                             ; syscall sys_exit
    mov rdi, 1                              ; código de salida 1 (error)
    syscall