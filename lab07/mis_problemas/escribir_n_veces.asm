section .data
    nombre_arch db "archito.txt", 0
    mensaje db "Hola desde ASM.", 10
    len equ $ - mensaje

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov r12, [rsp + 16]
    movzx r12, byte [r12]
    sub r12, '0'

    mov rax, 2
    mov rdi, nombre_arch
    mov rsi, 1101o
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    xor r13, r13

escribir:
    cmp r13, r12
    jge cerrar
    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
    syscall
    inc r13
    jmp escribir

cerrar:
    mov rax, 3
    mov rdi, rbx
    syscall

salir:
    mov rax, 60
    xor rdi, rdi
    syscall

salir_error:
    mov rax, 60
    mov rdi, 0xFF
    syscall