; =============================================================================
; Subrutina: itoa (System V AMD64 ABI)
; Entrada:   rdi = número entero sin signo (uint64)
;            rsi = puntero a un buffer de al menos 21 bytes (resb 21)
; Salida:    rax = puntero al primer dígito de la cadena (terminada en '\0')
;            rdx = longitud en bytes sin contar el '\0'
; Preserva:  rbx, rbp, rsp, r12-r15 (callee-saved)
; =============================================================================
%ifndef ITOA_ASM
%define ITOA_ASM

itoa:
    mov rax, rdi                ; rax = número a dividir
    lea r8, [rsi + 20]          ; r8 = final del buffer (byte 20)
    mov byte [r8], 0            ; colocar terminador nulo '\0'
    mov rcx, 10                 ; divisor base 10

.bucle:
    xor rdx, rdx                ; limpiar rdx antes de div (rdx:rax / rcx)
    div rcx                     ; rax = cociente, rdx = resto (0..9)
    add dl, '0'                 ; convertir dígito a carácter ASCII
    dec r8                      ; retroceder una posición en el buffer
    mov [r8], dl                ; guardar carácter
    test rax, rax               ; ¿quedan más dígitos? (funciona incluso si rdi=0)
    jnz .bucle

    lea rdx, [rsi + 20]         ; rdx = dirección del '\0'
    sub rdx, r8                 ; rdx = cantidad de dígitos escritos (2do retorno)
    mov rax, r8                 ; rax = puntero al primer dígito (1er retorno)
    ret

%endif
