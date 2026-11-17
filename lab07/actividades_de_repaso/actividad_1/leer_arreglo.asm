section .data
    arreglo db 2, 3, 4, 5       ; arreglo de 4 elementos de 1 byte c/u
    len equ $ - arreglo         ; tamaño en bytes = cantidad de elementos (4)

section .text
    global _start

_start:
    xor rcx, rcx                ; rcx = 0 (índice inicial del arreglo)
    xor rax, rax                ; limpia rax para leer en al sin basura en los bits altos

recorrer:
    cmp rcx, len                ; ¿ya llegamos al final? (rcx >= len)
    jge fin                     ; si sí, salir del bucle

    mov al, [arreglo + rcx]     ; lee arreglo[rcx] (1 byte) en al

    inc rcx                     ; avanza al siguiente índice (rcx++)
    jmp recorrer                ; repetir para el siguiente elemento


fin:
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0 (sin errores)
    syscall