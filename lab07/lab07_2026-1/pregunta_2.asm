;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond the HEADER is code
%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o

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

START:	; address label representing the entry point of our program
	; 1. Verificar que se recibieron exactamente 2 argumentos (argc == 3)
	mov rax, [rsp]				; rax = argc (desde el tope del process stack)
	cmp rax, 3					; argv[0] (exe), argv[1] (texto), argv[2] (N)
	jne salir_error

	; 2. Leer el dígito ASCII de N desde argv[2] (sin necesidad de convertir a entero)
	mov rsi, [rsp + 24]			; rsi = puntero a argv[2]
	mov bl, [rsi]				; bl = carácter ASCII de N ('1'..'9')

crear_loop:
	; 3. Crear/abrir "archivito_X": sys_open(nombre, flags, 644o)
	mov eax, 2								; syscall sys_open
	mov edi, nombre							; puntero al nombre del archivo
	mov esi, O_WRONLY | O_CREAT | O_TRUNC	; escritura + crear + vaciar
	mov edx, 644o							; permisos rw-r--r--
	syscall

	cmp eax, 0					; si eax < 0, error al crear/abrir
	jl salir_error

	; 4. Cerrar el archivo: sys_close(fd)
	mov edi, eax				; fd devuelto por sys_open
	mov eax, 3					; syscall sys_close
	syscall

	; 5. Incrementar sufijo ('1' -> '2' -> ...) y repetir hasta N
	inc byte [nombre + 10]		; avanza el carácter 'X' en "archivito_X"
	cmp [nombre + 10], bl		; ¿ya superamos N?
	jle crear_loop				; si <= N, crear el siguiente archivo

salir:
	mov eax, 60					; syscall sys_exit
	xor edi, edi				; código de salida 0
	syscall

salir_error:
	mov eax, 60					; syscall sys_exit
	mov edi, 0xFF				; código de salida 255 (error)
	syscall

	; Datos en el mismo segmento (después de sys_exit, antes de END)
	nombre db "archivito_1", 0	; nombre base con sufijo inicial '1' y '\0'

END:	; address label representing the end of our program

