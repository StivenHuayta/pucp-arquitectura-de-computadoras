; =============================================================================
; Plantilla: Abrir un archivo recibido por argumento (O_RDONLY) y cerrarlo
; Compilar:  nasm -f elf64 02_open_por_arg.asm && ld 02_open_por_arg.o -o exe
; Uso:       ./exe <archivo>
; =============================================================================

%define O_RDONLY 0              ; flag de solo lectura (Linux x86-64)

section .text
    global _start

_start:
    ; 1. Verificar que se recibió al menos 1 argumento (argc >= 2)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; argv[0] (programa), argv[1] (archivo)
    jl salir_error

    ; 2. Abrir archivo en modo solo lectura: sys_open(argv[1], O_RDONLY, 0)
    mov rax, 2                  ; syscall sys_open
    mov rdi, [rsp + 16]         ; rdi = argv[1] (nombre del archivo)
    mov rsi, O_RDONLY           ; solo lectura
    mov rdx, 0                  ; modo en 0 (no se crea archivo nuevo)
    syscall

    cmp rax, 0                  ; si rax < 0, ocurrió un error al abrir
    jl salir_error

    mov rbx, rax                ; guardar file descriptor (fd) en rbx

    ; 3. Cerrar el archivo: sys_close(fd)
    mov rax, 3                  ; syscall sys_close
    mov rdi, rbx                ; rdi = fd del archivo
    syscall

    ; 4. Salir sin errores: sys_exit(0)
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall