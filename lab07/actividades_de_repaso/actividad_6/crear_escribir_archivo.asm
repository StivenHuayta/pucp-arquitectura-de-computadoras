; =============================================================================
; Uso: ./crear_escribir_archivo <nombre_archivo> <texto>
; Crea (o sobrescribe) un archivo y escribe en él el texto recibido por argumento.
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe
%define O_APPEND 2000o          ; agregar al final (opcional, no usada aquí)

section .text
    global _start

_start:
    ; 1. Verificar que se recibieron al menos 2 argumentos (argc >= 3)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 3                  ; argv[0] (programa), argv[1] (archivo), argv[2] (texto)
    jl salir_error

    ; 2. Abrir o crear el archivo: sys_open(argv[1], flags, modo)
    mov rax, 2                              ; syscall sys_open
    mov rdi, [rsp + 16]                     ; rdi = argv[1] (nombre del archivo)
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC   ; escritura + crear + sobrescribir
    mov rdx, 644o                           ; permisos rw-r--r--
    syscall

    cmp rax, 0                  ; si rax < 0, ocurrió un error al abrir/crear
    jl salir_error

    mov rbx, rax                ; guardar file descriptor (fd) en rbx (syscall lo respeta)

    ; 3. Calcular la longitud del texto (argv[2]) en rdx
    mov rsi, [rsp + 24]         ; rsi = argv[2] (puntero al texto)
    xor rdx, rdx                ; rdx = 0 (contador de bytes)

contar:
    cmp byte [rsi + rdx], 0     ; ¿llegamos al fin de cadena ('\0')?
    je escribir                 ; si sí, rsi y rdx ya están listos para sys_write
    inc rdx                     ; longitud++
    jmp contar

    ; 4. Escribir el texto en el archivo: sys_write(fd, buffer, longitud)
escribir:
    mov rax, 1                  ; syscall sys_write
    mov rdi, rbx                ; rdi = fd del archivo
    syscall                     ; rsi = argv[2], rdx = longitud

    ; 5. Cerrar el archivo: sys_close(fd)
cerrar:
    mov rax, 3                  ; syscall sys_close
    mov rdi, rbx                ; rdi = fd del archivo
    syscall

    ; 6. Salir sin errores: sys_exit(0)
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall