; =============================================================================
; Plantilla Minimal ELF (Schizone): Recorrer una matriz 2D (i*cols + j)
; Compilar:  nasm -f bin 02_matriz_recorrido_minimal_elf.asm -o exe
;            chmod +x exe
; Uso:       gdb ./exe   (inspeccionar al/rbx/rcx paso a paso)
; =============================================================================

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond the HEADER is code

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

    ; Datos dentro del mismo segmento (después de sys_exit, antes de END)
    matriz db 1, 2, 3           ; fila 0 (3 elementos de 1 byte c/u)
           db 4, 5, 6           ; fila 1 (almacenada justo después en memoria)
    filas  equ 2                ; número total de filas
    cols   equ 3                ; número total de columnas

END:
