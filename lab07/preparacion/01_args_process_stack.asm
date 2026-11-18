; =============================================================================
; Plantilla: Leer argumento desde el Process Stack ([rsp+16]) e imprimirlo (write)
; Compilar:  nasm -f elf64 01_args_process_stack.asm && ld 01_args_process_stack.o -o exe
; Uso:       ./exe <texto>
; =============================================================================

section .data
    newline db 10               ; salto de línea ('\n') para imprimir al final

section .text
    global _start

_start:
    ; 1. Verificar que se recibió al menos 1 argumento (argc >= 2)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; argv[0] (programa), argv[1] (texto)
    jl salir_error

    ; 2. Calcular la longitud de argv[1] en rdx
    mov rsi, [rsp + 16]         ; rsi = puntero a argv[1] (buffer para sys_write)
    xor rdx, rdx                ; rdx = 0 (contador de caracteres)

contar:
    cmp byte [rsi + rdx], 0     ; ¿llegamos al fin de cadena ('\0')?
    je imprimir                 ; si sí, rsi y rdx están listos para sys_write
    inc rdx                     ; longitud++
    jmp contar

    ; 3. Imprimir argv[1] en stdout: sys_write(1, argv[1], longitud)
imprimir:
    mov rax, 1                  ; syscall sys_write
    mov rdi, 1                  ; fd = 1 (stdout)
    syscall

    ; 4. Imprimir salto de línea: sys_write(1, newline, 1)
    mov rax, 1                  ; syscall sys_write
    mov rdi, 1                  ; fd = 1 (stdout)
    mov rsi, newline            ; dirección del '\n'
    mov rdx, 1                  ; 1 byte
    syscall

    ; 5. Salir sin errores: sys_exit(0)
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall