; =============================================================================
; Subrutina: atoi (unsigned, sin espacios iniciales)
; Entrada:   rdi = puntero a la cadena terminada en 0 (ASCIIZ)
; Salida:    rax = número entero (uint64)
; =============================================================================
%ifndef ATOI_ASM
%define ATOI_ASM

atoi:
    xor rax, rax                ; rax = 0

.bucle:
    movzx rcx, byte [rdi]       ; Leer byte actual
    sub cl, '0'                 ; Convertir de ASCII a valor numérico (0-9)
    cmp cl, 9                   ; Si era < '0' o > '9', el valor sin signo será > 9
    ja .fin                     ; Se detiene ante cualquier no-dígito o byte nulo (0x00)

    ; rax = rax * 10 + rcx
    lea rax, [rax + rax * 4]    ; rax = rax * 5
    lea rax, [rcx + rax * 2]    ; rax = rax * 10 + rcx

    inc rdi                     ; Siguiente carácter
    jmp .bucle

.fin:
    ret

%endif
