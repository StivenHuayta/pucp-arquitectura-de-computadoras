section .text
    global _start

%include "atoi.asm"

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rdi, [rsp + 16]
    call atoi
    mov rdi, rax

    mov rax, 60
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall