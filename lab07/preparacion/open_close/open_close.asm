%define O_RDONLY 0

section .data
    filename db "archivo.txt", 0

section .text
    global _start

_start:
    mov rax, 2                  ; selecciona la syscall numero 2 (open)
    mov rdi, filename           ; nombre del archivo
    mov rsi, O_RDONLY           ; parametros de apertura (solo lectura)
    mov rdx, 0                  ; cero por default (solo se usa cuando se crea un nuevo archivo)
    syscall

    cmp rax, 0
    jl salida_error             ; si es menor a cero hubo un error

    mov rbx, rax                ; guardamos el file descriptor del archivo abierto

    mov rax, 3                  ; syscall numero 3 (close)
    mov rdi, rbx                ; file descriptor del archivo a cerrar
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

salida_error:
    mov rax, 60
    mov rdi, 1                  ; codigo de salida 1 (error)
    syscall