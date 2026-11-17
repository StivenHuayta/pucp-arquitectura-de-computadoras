## 1. Referencias útiles

Para trabajar con syscalls en ASM x86-64 Linux conviene usar dos tipos de referencias:

1. Una tabla rápida para consultar números de syscall y argumentos.
2. Las páginas del manual para recordar qué hace cada syscall.

### Tabla rápida de syscalls

- [Searchable Linux Syscall Table for x86_64](https://filippo.io/linux-syscall-table/)

Esta tabla permite buscar una syscall por nombre y ver:

- el número que va en `rax`;
- el nombre de la syscall;
- los argumentos;
- enlaces al manual;
- enlaces a la implementación en el kernel.

Ejemplo:

```text
write   -> rax = 1
open    -> rax = 2
close   -> rax = 3
exit    -> rax = 60
chmod   -> rax = 90
```

### Manuales útiles

```bash
man 2 syscall
man 2 open
man 2 close
man 2 write
man 2 read
man 2 chmod
man 1 strace
```

Enlaces:

- [`syscall(2)`](https://man7.org/linux/man-pages/man2/syscall.2.html)
- [`open(2)`](https://man7.org/linux/man-pages/man2/open.2.html)
- [`close(2)`](https://man7.org/linux/man-pages/man2/close.2.html)
- [`write(2)`](https://man7.org/linux/man-pages/man2/write.2.html)
- [`read(2)`](https://man7.org/linux/man-pages/man2/read.2.html)
- [`chmod(2)`](https://man7.org/linux/man-pages/man2/chmod.2.html)
- [`strace(1)`](https://man7.org/linux/man-pages/man1/strace.1.html)

---

## 2. Convención de registros para syscalls

En Linux x86-64, antes de ejecutar `syscall`, los registros se usan así:

| Elemento | Registro |
|---|---|
| Número de syscall | `rax` |
| Argumento 1 | `rdi` |
| Argumento 2 | `rsi` |
| Argumento 3 | `rdx` |
| Argumento 4 | `r10` |
| Argumento 5 | `r8` |
| Argumento 6 | `r9` |
| Valor de retorno | `rax` |

Ejemplo general:

```asm
mov rax, NUMERO_SYSCALL
mov rdi, ARGUMENTO_1
mov rsi, ARGUMENTO_2
mov rdx, ARGUMENTO_3
syscall
```

Para saber qué colocar en cada registro, se combinan dos datos:

1. la firma de la syscall en `man`;
2. la convención de registros de Linux x86-64.

Por ejemplo, `write` tiene esta firma:

```c
ssize_t write(int fd, const void *buf, size_t count);
```

Entonces:

| Argumento en C | Registro |
|---|---|
| `fd` | `rdi` |
| `buf` | `rsi` |
| `count` | `rdx` |

En ASM:

```asm
mov rax, 1          ; write
mov rdi, 1          ; fd = stdout
mov rsi, mensaje    ; buffer
mov rdx, len        ; cantidad de bytes
syscall
```

---

## 3. File descriptors

Un **file descriptor** es un número entero que identifica un recurso abierto por un proceso.

Ese recurso puede ser:

- la terminal;
- un archivo;
- una tubería;
- un socket;
- otro dispositivo.

Todo proceso inicia normalmente con tres file descriptors abiertos:

| File descriptor | Nombre | Significado |
|---:|---|---|
| `0` | `stdin` | entrada estándar |
| `1` | `stdout` | salida estándar |
| `2` | `stderr` | salida de errores |

Por ejemplo, en `write`:

```asm
mov rdi, 1
```

significa escribir en `stdout`.

En cambio:

```asm
mov rdi, 2
```

significa escribir en `stderr`.

Y si `open` devuelve un file descriptor en `rax`, por ejemplo `3`, entonces:

```asm
mov rdi, 3
```

puede significar escribir, leer o cerrar el archivo asociado al file descriptor `3`, dependiendo de la syscall usada.

La idea importante es:

```text
write no escribe necesariamente en pantalla.
write escribe en el file descriptor que se coloque en rdi.
```

---

## 4. `open` devuelve un file descriptor

Cuando se abre un archivo con `open`, el kernel devuelve un nuevo file descriptor en `rax`.

Normalmente, el primer archivo abierto por el programa recibe el file descriptor `3`, porque `0`, `1` y `2` ya están ocupados:

```text
0 = stdin
1 = stdout
2 = stderr
```

Por eso puede aparecer algo como:

```text
open("archivo.txt", O_RDONLY) = 3
```

El `3` no se inventa en el programa: lo devuelve el kernel.

Ese valor debe guardarse para usarlo luego con otras syscalls como `read`, `write` o `close`.

---

## 5. `open` y `close`

En Linux, `open` y `close` suelen usarse juntas.

- `open` abre o crea un archivo.
- `close` cierra el file descriptor devuelto por `open`.

Documentación:

- [`open(2)`](https://man7.org/linux/man-pages/man2/open.2.html)
- [`close(2)`](https://man7.org/linux/man-pages/man2/close.2.html)

### Números de syscall

| Syscall | Número |
|---|---:|
| `open` | `2` |
| `close` | `3` |

### Firmas en C

```c
int open(const char *pathname, int flags, mode_t mode);
int close(int fd);
```

### Argumentos de `open`

| Argumento | Registro | Significado |
|---|---|---|
| `pathname` | `rdi` | dirección del nombre del archivo |
| `flags` | `rsi` | forma de apertura |
| `mode` | `rdx` | permisos si se crea el archivo |

Si `open` funciona correctamente, `rax` contiene un file descriptor.

Si falla, `rax` contiene un valor negativo.

### Argumentos de `close`

| Argumento | Registro | Significado |
|---|---|---|
| `fd` | `rdi` | file descriptor a cerrar |

Si `close` funciona correctamente, devuelve `0`.

### Relación básica

```asm
mov rax, 2          ; open
mov rdi, filename
mov rsi, O_RDONLY
mov rdx, 0
syscall

mov rbx, rax        ; guardar fd

mov rax, 3          ; close
mov rdi, rbx        ; cerrar el fd devuelto por open
syscall
```

La relación importante es:

```text
open(...) devuelve un fd en rax.
Ese fd se guarda.
Ese mismo fd se usa con close(fd).
```

---

## 6. Flags de `open`

Los flags indican cómo se abrirá el archivo.

| Flag | Valor octal | Significado |
|---|---:|---|
| `O_RDONLY` | `0` | abrir solo lectura |
| `O_WRONLY` | `1` | abrir solo escritura |
| `O_RDWR` | `2` | abrir lectura y escritura |
| `O_CREAT` | `0100` | crear si no existe |
| `O_TRUNC` | `01000` | borrar contenido previo |
| `O_APPEND` | `02000` | escribir al final |

En NASM se pueden definir así:

```asm
%define O_RDONLY 0
%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o
%define O_APPEND 2000o
```

Los flags se combinan con OR:

```asm
O_WRONLY | O_CREAT | O_TRUNC
```

Eso significa:

```text
Abrir para escritura.
Crear si no existe.
Borrar el contenido previo si ya existía.
```

También puede usarse:

```asm
O_WRONLY | O_CREAT | O_APPEND
```

Eso significa:

```text
Abrir para escritura.
Crear si no existe.
Agregar al final del archivo.
```

Los valores numéricos de los flags se pueden verificar en los headers del sistema:

```bash
grep -R "# *define O_APPEND" /usr/include 2>/dev/null | head
```

---

## 7. El argumento `mode`

El tercer argumento de `open`, llamado `mode`, indica los permisos con los que se crea el archivo cuando se usa `O_CREAT`.

Por ejemplo:

```asm
mov rdx, 644o
```

indica permisos:

```text
rw-r--r--
```

El valor `644o` está en octal:

| Dígito | Usuario afectado | Permiso |
|---:|---|---|
| `6` | dueño | lectura + escritura |
| `4` | grupo | lectura |
| `4` | otros | lectura |

Si no se usa `O_CREAT`, el argumento `mode` no tiene efecto práctico.

---

## 8. Ejemplo: abrir y cerrar un archivo existente

Primero creamos el archivo necesario:

```bash
echo "Archivo de prueba" > archivo.txt
cat archivo.txt
```

Salida esperada:

```text
Archivo de prueba
```

Ahora el programa abrirá `archivo.txt` en modo solo lectura y luego lo cerrará.

Código:

```asm
%define O_RDONLY 0

section .data
filename db "archivo.txt", 0

section .text
global _start

_start:
    mov rax, 2
    mov rdi, filename
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación:

```bash
nasm -f elf64 open_close.asm -o open_close.o
ld open_close.o -o open_close
```

Ejecución:

```bash
./open_close
echo $?
```

Salida esperada:

```text
0
```

Verificación con `strace`:

```bash
strace -e trace=open,close,exit ./open_close
```

Salida esperada aproximada:

```text
open("archivo.txt", O_RDONLY) = 3
close(3)                      = 0
exit(0)                       = ?
+++ exited with 0 +++
```

Interpretación:

```text
open("archivo.txt", O_RDONLY) = 3
```

`open` devolvió el file descriptor `3`.

```text
close(3) = 0
```

`close` cerró correctamente ese mismo file descriptor.

---

## 9. Ejemplo: crear o truncar un archivo

Este ejemplo usa:

```asm
O_WRONLY | O_CREAT | O_TRUNC
```

Primero preparamos un archivo con contenido previo:

```bash
echo "Contenido anterior" > salida.txt
cat salida.txt
```

Salida esperada:

```text
Contenido anterior
```

Luego el programa abre `salida.txt`, borra el contenido anterior y escribe un nuevo mensaje.

Código:

```asm
%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o

section .data
filename db "salida.txt", 0
mensaje db "Nuevo contenido desde ASM", 10
len equ $ - mensaje

section .text
global _start

_start:
    mov rax, 2
    mov rdi, filename
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación:

```bash
nasm -f elf64 open_flags.asm -o open_flags.o
ld open_flags.o -o open_flags
```

Ejecución:

```bash
./open_flags
cat salida.txt
```

Salida esperada:

```text
Nuevo contenido desde ASM
```

La salida anterior:

```text
Contenido anterior
```

desaparece porque se usó:

```asm
O_TRUNC
```

Verificación con `strace`:

```bash
strace -e trace=open,write,close,exit ./open_flags
```

Salida esperada aproximada:

```text
open("salida.txt", O_WRONLY|O_CREAT|O_TRUNC, 0644) = 3
write(3, "Nuevo contenido desde ASM\n", 26) = 26
close(3)                                = 0
exit(0)                                 = ?
+++ exited with 0 +++
```

Interpretación:

| Línea | Significado |
|---|---|
| `open(...) = 3` | el archivo se abrió y el kernel devolvió el fd `3` |
| `write(3, ..., 26) = 26` | se escribieron `26` bytes en el archivo asociado al fd `3` |
| `close(3) = 0` | se cerró correctamente el fd `3` |
| `exit(0)` | el programa terminó correctamente |

---

## 10. Ejemplo: agregar contenido con `O_APPEND`

Este ejemplo usa:

```asm
O_WRONLY | O_CREAT | O_APPEND
```

A diferencia de `O_TRUNC`, `O_APPEND` no borra el contenido anterior. Escribe al final del archivo.

Primero preparamos el archivo necesario:

```bash
echo "Primera línea" > log.txt
cat log.txt
```

Salida esperada:

```text
Primera línea
```

Código:

```asm
%define O_WRONLY 1
%define O_CREAT  100o
%define O_APPEND 2000o

section .data
filename db "log.txt", 0
mensaje db "Línea agregada desde ASM", 10
len equ $ - mensaje

section .text
global _start

_start:
    mov rax, 2
    mov rdi, filename
    mov rsi, O_WRONLY | O_CREAT | O_APPEND
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación:

```bash
nasm -f elf64 open_append.asm -o open_append.o
ld open_append.o -o open_append
```

Ejecución:

```bash
./open_append
cat log.txt
```

Salida esperada:

```text
Primera línea
Línea agregada desde ASM
```

Verificación con `strace`:

```bash
strace -e trace=open,write,close,exit ./open_append
```

Salida esperada aproximada:

```text
open("log.txt", O_WRONLY|O_CREAT|O_APPEND, 0644) = 3
write(3, "Línea agregada desde ASM\n", 25) = 25
close(3)                                = 0
exit(0)                                 = ?
+++ exited with 0 +++
```

Comparación:

| Flags | Efecto |
|---|---|
| `O_WRONLY | O_CREAT | O_TRUNC` | crea si no existe y borra contenido previo |
| `O_WRONLY | O_CREAT | O_APPEND` | crea si no existe y agrega al final |

---

## 11. Process stack y argumentos del programa

Cuando un programa empieza, Linux prepara una pila inicial para ese proceso. Esta pila se conoce como **process stack** o **pila del proceso**.

Al iniciar en `_start`, `rsp` apunta al inicio de esa pila.

En ella se encuentran los argumentos del programa:

```text
[rsp]      = argc
[rsp + 8]  = argv[0]
[rsp + 16] = argv[1]
[rsp + 24] = argv[2]
[rsp + 32] = argv[3]
...
```

Por ejemplo, si ejecutamos:

```bash
./programa archivo.txt 777
```

tenemos:

```text
argc    = 3
argv[0] = "./programa"
argv[1] = "archivo.txt"
argv[2] = "777"
```

Diferencia importante:

```text
Los argumentos de una syscall se pasan por registros.

Los argumentos escritos al ejecutar un programa se encuentran inicialmente
en la pila del proceso.
```

Ejemplo de lectura desde la pila:

```asm
mov rax, [rsp]       ; argc
mov rdi, [rsp + 16]  ; argv[1]
mov rsi, [rsp + 24]  ; argv[2]
```

---

## 12. Ejemplo: leer `argv[1]`

Este programa obtiene `argv[1]` desde la pila del proceso y lo imprime.

Uso esperado:

```bash
./leer_arg hola
```

Salida esperada:

```text
hola
```

Código:

```asm
section .data
newline db 10

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rsi, [rsp + 16]

    xor rdx, rdx

contar:
    cmp byte [rsi + rdx], 0
    je imprimir
    inc rdx
    jmp contar

imprimir:
    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 leer_arg.asm -o leer_arg.o
ld leer_arg.o -o leer_arg
./leer_arg hola
```

Verificación con `strace`:

```bash
strace -e trace=write,exit ./leer_arg hola
```

Salida esperada aproximada:

```text
write(1, "hola", 4) = 4
write(1, "\n", 1)   = 1
exit(0)             = ?
+++ exited with 0 +++
```

---

## 13. Ejemplo: abrir archivo usando `argv[1]`

Ahora el nombre del archivo no estará escrito en `.data`, sino que se leerá desde la pila del proceso.

Primero creamos el archivo necesario:

```bash
echo "Archivo usando argv" > archivo.txt
cat archivo.txt
```

Uso esperado:

```bash
./abrir archivo.txt
```

Código:

```asm
%define O_RDONLY 0

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación:

```bash
nasm -f elf64 abrir.asm -o abrir.o
ld abrir.o -o abrir
```

Ejecución:

```bash
./abrir archivo.txt
echo $?
```

Salida esperada:

```text
0
```

Verificación con `strace`:

```bash
strace -e trace=open,close,exit ./abrir archivo.txt
```

Salida esperada aproximada:

```text
open("archivo.txt", O_RDONLY) = 3
close(3)                      = 0
exit(0)                       = ?
+++ exited with 0 +++
```

Prueba con error:

```bash
strace -e trace=open,close,exit ./abrir no_existe.txt
```

Salida esperada aproximada:

```text
open("no_existe.txt", O_RDONLY) = -1 ENOENT (No such file or directory)
exit(1)                         = ?
+++ exited with 1 +++
```

---

## 14. Programa tipo `touch`

El comando `touch` puede crear un archivo vacío. Aquí haremos una versión simple.

Uso esperado:

```bash
./mi_touch nuevo.txt
```

El programa debe:

1. leer `argv[1]`;
2. crear el archivo si no existe;
3. cerrarlo;
4. terminar.

Código:

```asm
%define O_WRONLY 1
%define O_CREAT  100o

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_WRONLY | O_CREAT
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 mi_touch.asm -o mi_touch.o
ld mi_touch.o -o mi_touch
./mi_touch nuevo.txt
ls -l nuevo.txt
```

Resultado esperado aproximado:

```text
-rw-r--r--
```

Verificación con `strace`:

```bash
strace -e trace=open,close,exit ./mi_touch nuevo.txt
```

Salida esperada aproximada:

```text
open("nuevo.txt", O_WRONLY|O_CREAT, 0644) = 3
close(3)                                  = 0
exit(0)                                   = ?
+++ exited with 0 +++
```

---

## 15. Crear archivo usando `argv[1]` y escribir contenido

Este programa recibe el nombre del archivo por argumento, lo crea o trunca, escribe `Hola mundo` y lo cierra.

Uso esperado:

```bash
./crear_hola salida.txt
```

Código:

```asm
%define O_WRONLY 1
%define O_CREAT  100o
%define O_TRUNC  1000o

section .data
mensaje db "Hola mundo", 10
len equ $ - mensaje

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 644o
    syscall

    cmp rax, 0
    jl salir_error

    mov rbx, rax

    mov rax, 1
    mov rdi, rbx
    mov rsi, mensaje
    mov rdx, len
    syscall

    mov rax, 3
    mov rdi, rbx
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 crear_hola.asm -o crear_hola.o
ld crear_hola.o -o crear_hola
./crear_hola salida.txt
cat salida.txt
```

Salida esperada:

```text
Hola mundo
```

Verificación con `strace`:

```bash
strace -e trace=open,write,close,exit ./crear_hola salida.txt
```

Salida esperada aproximada:

```text
open("salida.txt", O_WRONLY|O_CREAT|O_TRUNC, 0644) = 3
write(3, "Hola mundo\n", 11) = 11
close(3)                    = 0
exit(0)                     = ?
+++ exited with 0 +++
```

---

## 16. Syscall `chmod`

La syscall `chmod` cambia los permisos de un archivo.

Documentación:

- [`chmod(2)`](https://man7.org/linux/man-pages/man2/chmod.2.html)

Número de syscall en x86-64 Linux:

| Syscall | Número |
|---|---:|
| `chmod` | `90` |

Firma en C:

```c
int chmod(const char *pathname, mode_t mode);
```

Argumentos:

| Argumento | Registro | Significado |
|---|---|---|
| `pathname` | `rdi` | dirección del nombre del archivo |
| `mode` | `rsi` | permisos |

Permisos comunes:

| Permiso | NASM | Significado |
|---|---:|---|
| `0644` | `644o` | `rw-r--r--` |
| `0755` | `755o` | `rwxr-xr-x` |
| `0777` | `777o` | `rwxrwxrwx` |

Ejemplo de preparación:

```asm
mov rax, 90         ; chmod
mov rdi, filename
mov rsi, 777o
syscall
```

---

## 17. Programa tipo `chmod` con nombre fijo

Primero creamos el archivo necesario:

```bash
touch archivo.txt
ls -l archivo.txt
```

Este programa cambia los permisos de `archivo.txt` a `0777`.

Código:

```asm
section .data
filename db "archivo.txt", 0

section .text
global _start

_start:
    mov rax, 90
    mov rdi, filename
    mov rsi, 777o
    syscall

    cmp rax, 0
    jl salir_error

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 chmod_fijo.asm -o chmod_fijo.o
ld chmod_fijo.o -o chmod_fijo
./chmod_fijo
ls -l archivo.txt
```

Salida esperada aproximada:

```text
-rwxrwxrwx
```

Verificación con `strace`:

```bash
strace -e trace=chmod,exit ./chmod_fijo
```

Salida esperada aproximada:

```text
chmod("archivo.txt", 0777) = 0
exit(0)                    = ?
+++ exited with 0 +++
```

---

## 18. Programa tipo `chmod` usando `argv[1]`

Este programa recibe el nombre del archivo por argumento y cambia sus permisos a `0777`.

Primero creamos el archivo necesario:

```bash
touch prueba.txt
ls -l prueba.txt
```

Uso esperado:

```bash
./mi_chmod prueba.txt
```

Código:

```asm
section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 90
    mov rdi, [rsp + 16]
    mov rsi, 777o
    syscall

    cmp rax, 0
    jl salir_error

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 mi_chmod.asm -o mi_chmod.o
ld mi_chmod.o -o mi_chmod
./mi_chmod prueba.txt
ls -l prueba.txt
```

Salida esperada aproximada:

```text
-rwxrwxrwx
```

Verificación con `strace`:

```bash
strace -e trace=chmod,exit ./mi_chmod prueba.txt
```

Salida esperada aproximada:

```text
chmod("prueba.txt", 0777) = 0
exit(0)                   = ?
+++ exited with 0 +++
```

---

## 19. Programa tipo `chmod 755` usando `argv[1]`

Este programa recibe el nombre del archivo por argumento y cambia sus permisos a `0755`.

Primero creamos el archivo necesario:

```bash
touch programa.sh
ls -l programa.sh
```

Uso esperado:

```bash
./mi_chmod755 programa.sh
```

Código:

```asm
section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl salir_error

    mov rax, 90
    mov rdi, [rsp + 16]
    mov rsi, 755o
    syscall

    cmp rax, 0
    jl salir_error

    mov rax, 60
    mov rdi, 0
    syscall

salir_error:
    mov rax, 60
    mov rdi, 1
    syscall
```

Compilación y ejecución:

```bash
nasm -f elf64 mi_chmod755.asm -o mi_chmod755.o
ld mi_chmod755.o -o mi_chmod755
./mi_chmod755 programa.sh
ls -l programa.sh
```

Salida esperada aproximada:

```text
-rwxr-xr-x
```

Verificación con `strace`:

```bash
strace -e trace=chmod,exit ./mi_chmod755 programa.sh
```

Salida esperada aproximada:

```text
chmod("programa.sh", 0755) = 0
exit(0)                    = ?
+++ exited with 0 +++
```
