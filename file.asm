; file related functions. This file contains functions for:
;           open, read, close file operations
; -----------------------------------------------------------

section .data

; -----
; Constants

SYS_read                equ 0       ; read() syscall
SYS_write               equ 1       ; write() syscall
SYS_open                equ 2       ; file open services
SYS_close               equ 3       ; file close
O_RDONLY                equ 0       ; readonly access
STDOUT                  equ 1       ; standard output (screen)
LF                      equ 10      ; newline character
EISDIR                  equ -21     ; we can't read directory
BUFFSIZE                equ 100

section .text

; -----
; openFile() -- opens a file
; HLL call: int fd = openFile(path);
; Arguments:
;   1) path to file, string (RDI)
; Returns:
;   file descriptor on success
;   error code on failure
global openFile
openFile:
    mov rax, SYS_open
    mov rsi, O_RDONLY               ; open file for reading only
    syscall                         ; path is passed through rdi already
    ret

; -----
; closeFile() -- closes a file
; HLL call: closeFile(fd);
; Arguments:
;   1) file descriptor, integer (RDI)
; Returns:
;   nothing
global closeFile
closeFile:
    mov rax, SYS_close
    syscall                         ; file descriptor already passed through rdi
    ret

; -----
; readLines() -- reads number of lines from file
; HLL call: readLines(fd, n);
; Arguments:
;   1) file descriptor (RDI)
;   2) n-lines (RSI)
; Returns:
;   nothing
global readLines
readLines:
    push rbp
    mov rbp, rsp
; We need exactly 13 bytes on the stack to save arguments from call frame
;   * 8 bytes for file descriptor
;   * 4 bytes for number of lines to read
;   * 1 byte  for current character
    sub rsp, 13
    push rbx
    push r12
    push r13

    lea rbx, dword [rbp-13]
    mov qword [rbx], rdi            ; file descriptor
    mov dword [rbx+8], esi          ; number of lines to read
    lea r13, byte [rbx+12]          ; single character from file

    mov r12, 0
readLoop:
; when -1 is passed as a number of lines to read we will skip the code
; which checks number of lines. This will cause to read whole file
    cmp dword [rbx+8], -1
    je ReadFile
    
    cmp r12d, dword [rbx+8]         ; check if we've reached lines limit
    je readEnd

; Read a single characer from file descriptor an save it in local variable
; on stack
ReadFile:
    mov rax, SYS_read
    mov rdi, qword [rbx]
    mov rsi, r13
    mov rdx, 1
    syscall

; when no characters left, just end the function
    cmp rax, 0
    je readEnd

; ISDIR exception
    cmp rax, EISDIR
    je readEnd

; Other errors
    cmp rax, 0
    jb readEnd

; Print on the screen saved character
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, r13
    mov rdx, 1
    syscall

; Count newline
    cmp byte [r13], LF
    je CountLine
    jmp readLoop

CountLine:
    inc r12
    jmp readLoop

; Function end. Restoring stack to previous state
readEnd:
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

global readLines2
readLines2:
    push rbp
    mov rbp, rsp
    sub rsp, 113
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdx

    lea rbx, qword [rbp-113]

    mov qword [rbx], rdi                ; 1'st arg: file descriptor
    mov dword [rbx+8], esi              ; 2'nd arg: number of lines
    lea r13, qword [rbx+12]             ; pointer to single character.
    lea r14, qword [rbx+13]             ; pointer to local buffer

    mov r12, 0
    mov rdx, 0
    mov r15, 0
readLoop2:
    cmp dword [rbx+8], -1
    je bufferLoop

checkLines:
    cmp dword [rbx+8], r15d
    je readEnd2

bufferLoop:
    mov rax, SYS_read
    mov rdi, qword [rbx]
    mov rsi, r13
    mov rdx, 1
    syscall

    cmp rax, 0
    je readEnd2

    cmp rax, EISDIR
    je readEnd2
    
; Saving data in the buffer
    mov r10b, byte [r13]
    mov byte [r14+r12], r10b
    inc r12                            ; chars in buffer

    cmp r12, BUFFSIZE
    je printBuffer
    cmp r10b, LF
    je printBuffer

    jmp readLoop2

printBuffer:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, r14
    mov rdx, r12
    syscall

    mov r12, 0
    inc r15
    jmp readLoop2

readEnd2:
    pop rdx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret