; =============================================================================
; Plantilla: Crear archivo vacío pasado por argumento (imita comando "touch")
; Compilar:  nasm -f elf64 04_open_creat_touch.asm && ld 04_open_creat_touch.o -o exe
; Uso:       ./exe <nuevo_archivo>
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe

section .text
    global _start

_start:
    ; 1. Verificar que se recibió al menos 1 argumento (argc >= 2)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; argv[0] (programa), argv[1] (archivo)
    jl salir_error

    ; 2. Crear/abrir el archivo vacío: sys_open(argv[1], O_WRONLY | O_CREAT, 644o)
    mov rax, 2                  ; syscall sys_open
    mov rdi, [rsp + 16]         ; rdi = argv[1] (nombre del archivo)
    mov rsi, O_WRONLY | O_CREAT ; escritura + crear si no existe
    mov rdx, 644o               ; permisos rw-r--r-- si se crea
    syscall

    cmp rax, 0                  ; si rax < 0, ocurrió un error al crear/abrir
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