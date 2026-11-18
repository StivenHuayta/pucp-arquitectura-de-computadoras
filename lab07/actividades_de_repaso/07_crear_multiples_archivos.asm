; =============================================================================
; Uso: ./crear_archivos <nombre_base> <cantidad_un_digito>
; Ejemplo: ./crear_archivos archivito 4 -> crea archivito1..archivito4 vacíos.
; =============================================================================

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe
%define O_APPEND 2000o          ; agregar al final (opcional, no usada aquí)

section .bss
    nombre resb 256             ; buffer para "<nombre_base><dígito>\0"

section .text
    global _start

_start:
    ; 1. Verificar que se recibieron al menos 2 argumentos (argc >= 3)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 3                  ; argv[0] (programa), argv[1] (nombre), argv[2] (N)
    jl salir_error

    ; 2. Convertir el dígito ASCII de argv[2] a número entero (N) en r12
    mov rsi, [rsp + 24]         ; rsi = argv[2]
    movzx r12, byte [rsi]       ; lee el carácter (ej. '4')
    sub r12, '0'                ; convierte ASCII -> entero (ej. 4)

    ; 3. Copiar argv[1] al buffer 'nombre' y guardar su longitud en r13
    mov rsi, [rsp + 16]         ; fuente: argv[1]
    mov rdi, nombre             ; destino: buffer 'nombre'
    xor r13, r13                ; r13 = longitud = 0

copiar_base:
    mov al, [rsi + r13]         ; lee carácter actual de argv[1]
    cmp al, 0                   ; ¿fin de cadena ('\0')?
    je listo_base
    mov [rdi + r13], al         ; copia al buffer
    inc r13                     ; longitud++
    jmp copiar_base

listo_base:
    mov byte [rdi + r13 + 1], 0 ; coloca '\0' justo después del espacio del dígito

    ; 4. Crear los N archivos vacíos: desde rbx = 1 hasta r12 (N)
    mov rbx, 1                  ; contador de archivo actual (1..N)

crear_loop:
    cmp rbx, r12                ; ¿ya creamos los N archivos?
    jg fin

    ; Escribir el dígito sufijo ('1', '2', ...) al final del nombre base
    mov al, bl                  ; toma el número actual (1..9)
    add al, '0'                 ; convierte entero -> ASCII ('1'..'9')
    mov [nombre + r13], al      ; coloca el dígito en su posición

    ; Crear/abrir archivo: sys_open(nombre, flags, 644o)
    mov rax, 2                              ; syscall sys_open
    mov rdi, nombre                         ; ruta del archivo
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC   ; escritura + crear + vaciar
    mov rdx, 644o                           ; permisos rw-r--r--
    syscall

    cmp rax, 0                  ; si rax < 0, hubo error al crear
    jl salir_error

    ; Cerrar archivo: sys_close(fd)
    mov rdi, rax                ; fd devuelto por sys_open
    mov rax, 3                  ; syscall sys_close
    syscall

    inc rbx                     ; siguiente número de archivo
    jmp crear_loop

fin:
    mov rax, 60                 ; syscall sys_exit
    xor rdi, rdi                ; código de salida 0 (sin errores)
    syscall

salir_error:
    mov rax, 60                 ; syscall sys_exit
    mov rdi, 1                  ; código de salida 1 (error)
    syscall