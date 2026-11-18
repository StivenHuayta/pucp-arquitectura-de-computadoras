; =============================================================================
; Plantilla: Abrir/crear archivo ("log.txt") y agregar texto al final (O_APPEND)
; Compilar:  nasm -f elf64 07_open_append.asm && ld 07_open_append.o -o exe
; Uso:       ./exe
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_APPEND 2000o          ; agregar al final sin borrar contenido previo

section .data
    filename db "log.txt", 0                    ; nombre del archivo terminado en '\0'
    mensaje  db "Línea agregada desde ASM.", 10 ; texto a agregar con '\n'
    len      equ $ - mensaje                    ; longitud del mensaje en bytes

section .text
    global _start

_start:
    ; 1. Abrir o crear el archivo en modo append: sys_open(filename, flags, 644o)
    mov rax, 2                              ; syscall sys_open
    mov rdi, filename                       ; nombre del archivo
    mov rsi, O_WRONLY | O_CREAT | O_APPEND  ; escritura + crear + agregar al final
    mov rdx, 644o                           ; permisos rw-r--r-- si se crea
    syscall

    cmp rax, 0                              ; si rax < 0, ocurrió un error
    jl salida_error

    mov rbx, rax                            ; guardar file descriptor (fd) en rbx

    ; 2. Escribir al final del archivo: sys_write(fd, mensaje, len)
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