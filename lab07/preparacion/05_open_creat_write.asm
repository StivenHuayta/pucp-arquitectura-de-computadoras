; =============================================================================
; Plantilla: Crear/sobrescribir archivo por argumento y escribir texto fijo (write)
; Compilar:  nasm -f elf64 05_open_creat_write.asm && ld 05_open_creat_write.o -o exe
; Uso:       ./exe <archivo_salida>
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe

section .data
    mensaje db "Hola mundo", 10 ; texto a escribir con salto de línea
    len equ $ - mensaje         ; longitud del mensaje en bytes

section .text
    global _start

_start:
    ; 1. Verificar que se recibió al menos 1 argumento (argc >= 2)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; argv[0] (programa), argv[1] (archivo)
    jl salir_error

    ; 2. Crear o sobrescribir el archivo: sys_open(argv[1], flags, 644o)
    mov rax, 2                              ; syscall sys_open
    mov rdi, [rsp + 16]                     ; rdi = argv[1] (nombre del archivo)
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC   ; escritura + crear + vaciar
    mov rdx, 644o                           ; permisos rw-r--r--
    syscall

    cmp rax, 0                  ; si rax < 0, ocurrió un error al abrir/crear
    jl salir_error

    mov rbx, rax                ; guardar file descriptor (fd) en rbx

    ; 3. Escribir el mensaje fijo: sys_write(fd, mensaje, len)
    mov rax, 1                  ; syscall sys_write
    mov rdi, rbx                ; rdi = fd del archivo
    mov rsi, mensaje            ; buffer a escribir
    mov rdx, len                ; cantidad de bytes
    syscall

    ; 4. Cerrar el archivo: sys_close(fd)
    mov rax, 3                  ; syscall sys_close
    mov rdi, rbx                ; rdi = fd del archivo
    syscall

    ; 5. Salir sin errores: sys_exit(0)
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall