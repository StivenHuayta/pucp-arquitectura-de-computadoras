; =============================================================================
; Plantilla: Leer 1 dígito por argumento y devolverlo en syscall exit (0xFF si error)
; Compilar:  nasm -f elf64 arg_exit_elf64.asm && ld arg_exit_elf64.o -o exe
; Uso:       ./exe 5 && echo $?
; Nota:      Para 2 o más dígitos, incluir "atoi.asm" y llamar a atoi sobre [rsp+16]
; =============================================================================

section .text
    global _start

_start:
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; verificar exactamente 2 argumentos (programa + número)
    jne salir_error

    mov rsi, [rsp + 16]         ; rsi = puntero a argv[1]
    movzx rdi, byte [rsi]       ; leer 1er carácter ASCII (extensión con ceros)
    sub rdi, '0'                ; convertir ASCII -> entero (0..9)

    mov rax, 60                 ; syscall sys_exit(rdi)
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit(0xFF)
    mov rdi, 0xFF               ; 255 en echo $?
    syscall
