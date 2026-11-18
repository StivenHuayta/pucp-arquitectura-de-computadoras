; =============================================================================
; Plantilla: Leer exactamente 2 dígitos por argumento y devolverlos en sys_exit
; Compilar:  nasm -f elf64 arg_exit_2digitos.asm && ld arg_exit_2digitos.o -o exe
; Uso:       ./exe 42 && echo $?
; Nota:      Para cantidad variable de dígitos, usar atoi.asm
; =============================================================================

section .text
    global _start

_start:
    mov rax, [rsp]              ; rax = argc
    cmp rax, 2                  ; verificar exactamente 2 argumentos (programa + número)
    jne salir_error

    mov rsi, [rsp + 16]         ; rsi = puntero a argv[1] (ej. "42")
    movzx r8, byte [rsi]        ; leer decenas en ASCII ('4')
    movzx r9, byte [rsi + 1]    ; leer unidades en ASCII ('2')

    sub r8, '0'                 ; convertir decenas ASCII -> entero (4)
    sub r9, '0'                 ; convertir unidades ASCII -> entero (2)

    imul r8, 10                 ; r8 = decenas * 10 (40)
    mov rdi, r8                 ; rdi = 40
    add rdi, r9                 ; rdi = 40 + 2 = 42

    mov rax, 60                 ; syscall sys_exit(rdi)
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit(0xFF)
    mov rdi, 0xFF               ; 255 en echo $?
    syscall
