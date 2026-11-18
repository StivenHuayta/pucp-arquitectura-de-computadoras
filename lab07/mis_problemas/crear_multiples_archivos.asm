%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe
%define O_APPEND 2000o          ; agregar al final (opcional, no usada aquí)

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 3
    jne salir_error

    mov r12, [rsp + 24]
    movzx r12, byte [r12]
    sub r12, '0'

    mov

    

salir:
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0 (sin errores)
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 0xFF               ; código de salida 1 (error)
    syscall