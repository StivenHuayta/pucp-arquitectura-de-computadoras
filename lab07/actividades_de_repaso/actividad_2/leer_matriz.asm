section .data
    matriz db 1, 2, 3           ; fila 0 (3 elementos de 1 byte c/u)
           db 4, 5, 6           ; fila 1 (almacenada justo después en memoria)
    filas  equ 2                ; número total de filas
    cols   equ 3                ; número total de columnas

section .text
    global _start

_start:
    xor rbx, rbx                ; rbx = i = 0 (índice de la fila actual)

bucle_fila:
    cmp rbx, filas              ; ¿ya recorrimos todas las filas? (i >= filas)
    jge fin                     ; si sí, salir del programa

    xor rcx, rcx                ; rcx = j = 0 (reinicia el índice de columna en cada fila)

bucle_col:
    cmp rcx, cols               ; ¿ya recorrimos todas las columnas de esta fila? (j >= cols)
    jge sig_fila                ; si sí, pasar a la siguiente fila

    ; Calcular desplazamiento lineal en memoria: índice = i * cols + j
    mov rax, rbx                ; rax = i
    imul rax, cols              ; rax = i * cols (salta filas completas)
    add rax, rcx                ; rax = i * cols + j (avanza a la columna j)

    mov al, [matriz + rax]      ; lee matriz[i][j] (1 byte) en al

    inc rcx                     ; j++ (siguiente columna)
    jmp bucle_col               ; repetir bucle de columnas

sig_fila:
    inc rbx                     ; i++ (siguiente fila)
    jmp bucle_fila              ; repetir bucle de filas


fin:
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0 (sin errores)
    syscall
