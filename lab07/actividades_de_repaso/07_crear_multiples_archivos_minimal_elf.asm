; =============================================================================
; Plantilla Minimal ELF (Schizone): Crear N archivos "<nombre_base>1..N" vacíos
; Compilar:  nasm -f bin 07_crear_multiples_archivos_minimal_elf.asm -o exe
;            chmod +x exe
; Uso:       ./exe <nombre_base> <cantidad_un_digito>
; Ejemplo:   ./exe archivito 4   -> crea archivito1..archivito4 vacíos.
; =============================================================================

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond the HEADER is code

; Flags para sys_open (en octal, según Linux x86-64)
%define O_WRONLY 1              ; solo escritura
%define O_CREAT  100o           ; crear si no existe
%define O_TRUNC  1000o          ; truncar (vaciar) si ya existe

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEADER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITS 64
org LOAD_ADDRESS
ELF_HEADER:
	db 0x7F,"ELF" ; magic number to indicate ELF file
	db 0x02 ; 0x1 for 32-bit, 0x2 for 64-bit
	db 0x01 ; 0x1 for little endian, 0x2 for big endian
	db 0x01 ; 0x1 for current version of ELF
	db 0x09 ; 0x9 for FreeBSD, 0x3 for Linux (doesn't seem to matter)
	db 0x00 ; ABI version (ignored?)
	times 7 db 0x00 ; 7 padding bytes
	dw 0x0002 ; executable file
	dw 0x003E ; AMD x86-64
	dd 0x00000001 ; version 1
	dq START ; entry point for our program
	dq 0x0000000000000040 ; 0x40 offset from ELF_HEADER to PROGRAM_HEADER
	dq 0x0000000000000000 ; section header offset (we don't have this)
	dd 0x00000000 ; unused flags
	dw 0x0040 ; 64-byte size of ELF_HEADER
	dw 0x0038 ; 56-byte size of each program header entry
	dw 0x0001 ; number of program header entries (we have one)
	dw 0x0000 ; size of each section header entry (none)
	dw 0x0000 ; number of section header entries (none)
	dw 0x0000 ; index in section header table for section names (waste)
PROGRAM_HEADER:
	dd 0x00000001 ; 0x1 for loadable program segment
	dd 0x00000007 ; read/write/execute flags
	dq 0x0000000000000078 ; offset of code start in file image (0x40+0x38)
	dq LOAD_ADDRESS+0x78 ; virtual address of segment in memory
	dq 0x0000000000000000 ; physical address of segment in memory (ignored?)
	dq CODE_SIZE ; size (bytes) of segment in file image
	dq CODE_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; external assembly files will be included here

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
    ; 1. Verificar que se recibieron al menos 2 argumentos (argc >= 3)
    mov rax, [rsp]              ; rax = argc
    cmp rax, 3                  ; argv[0] (programa), argv[1] (nombre), argv[2] (N)
    jl salir_error

    ; 2. Leer puntero a argv[1] y convertir el dígito ASCII de argv[2] a entero en r12
    mov rsi, [rsp + 16]         ; rsi = argv[1] (nombre base)
    mov rax, [rsp + 24]         ; rax = argv[2] (cantidad)
    movzx r12, byte [rax]       ; lee el carácter (ej. '4')
    sub r12, '0'                ; convierte ASCII -> entero (ej. 4)

    ; 3. Reservar 256 bytes en la pila como buffer (en lugar de .bss)
    sub rsp, 256                ; rsp ahora apunta al buffer "<nombre_base><dígito>\0"
    xor r13, r13                ; r13 = longitud = 0

copiar_base:
    mov al, [rsi + r13]         ; lee carácter actual de argv[1]
    cmp al, 0                   ; ¿fin de cadena ('\0')?
    je listo_base
    mov [rsp + r13], al         ; copia al buffer en la pila
    inc r13                     ; longitud++
    jmp copiar_base

listo_base:
    mov byte [rsp + r13 + 1], 0 ; coloca '\0' justo después del espacio del dígito

    ; 4. Crear los N archivos vacíos: desde rbx = 1 hasta r12 (N)
    mov rbx, 1                  ; contador de archivo actual (1..N)

crear_loop:
    cmp rbx, r12                ; ¿ya creamos los N archivos?
    jg fin

    ; Escribir el dígito sufijo ('1', '2', ...) al final del nombre base
    mov al, bl                  ; toma el número actual (1..9)
    add al, '0'                 ; convierte entero -> ASCII ('1'..'9')
    mov [rsp + r13], al         ; coloca el dígito en su posición dentro del buffer

    ; Crear/abrir archivo: sys_open(rsp, flags, 644o)
    mov rax, 2                              ; syscall sys_open
    mov rdi, rsp                            ; ruta del archivo (buffer en la pila)
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

END:
