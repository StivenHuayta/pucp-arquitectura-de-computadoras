section .data:
    newline db 10

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2                  ; si hay menos de 2 argumentos (argc y argv[0]) salir
    jl salir_error

    mov rsi, [rsp + 16]         ; ponemos la cadena en el registro donde va la cadena para el write

    xor rdx, rdx                ; inicializamos el contador de caracteres

contar:
    cmp byte [rsi + rdx], 0
    je imprimir
    inc rdx
    jmp contar

imprimir:
    mov rax, 1                  ; fd de stdout
    mov rdi, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall