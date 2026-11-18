; =============================================================================
; Plantilla: Leer número de N dígitos por argumento (atoi) y devolverlo en exit
; Compilar:  nasm -f elf64 arg_exit_atoi_elf64.asm && ld arg_exit_atoi_elf64.o -o exe
; Uso:       ./exe 123 && echo $?
; =============================================================================

section .text
    global _start

%include "atoi.asm"

_start:
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; verificar exactamente 2 argumentos (programa + número)
    jne salir_error

    mov rdi, [rsp + 16]         ; 1er arg para atoi: puntero a argv[1]
    call atoi                   ; retorna en rax el entero convertido
    mov rdi, rax                ; pasar resultado a sys_exit

    mov rax, 60                 ; syscall sys_exit(rdi)
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit(0xFF)
    mov rdi, 0xFF               ; 255 en echo $?
    syscall
