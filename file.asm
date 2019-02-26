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
BUFFSIZE                equ 512

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
; Stack reservation for arguments and local variables.
; We need BUFFSIZE (512 bytes) + 17 bytes
; * 8 bytes:   1'st argument - file descriptor
; * 8 bytes:   2'nd argument - number of lines to display
; * 1 byte:    local variable for single character
; * 512 bytes: local character array for buffer
    sub rsp, BUFFSIZE+17
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdx

    lea rbx, qword [rbp-BUFFSIZE+17]

    mov qword [rbx], rdi                ; 1'st arg: file descriptor
    mov qword [rbx+8], rsi              ; 2'nd arg: number of lines
    lea r13, qword [rbx+16]             ; pointer to single character.
    lea r14, qword [rbx+17]             ; pointer to local buffer

    mov r12, 0                          ; buffer index
    mov rdx, 0                          ; number of characters used in syscalls
    mov r15, 0                          ; number of newline characters

readLoop:
; Algorithm:
;   1) check number of newlines
;   2) if number is below limit, read single characer from file
;   3) check if it is not Directory
;   4) check if operation was successful
;   5) save character in buffer
;   6) check if we've reached buffer size
;       6a) if buffer size is reached, display buffer on the screen
;       6b) if  current character in buffer is a newline: display buffer
;           and reset buffer index, increment newline count
;   7) read next character from file
; -------------------------------------------------------------------

; Simple trick to skip optional argument with lines to display.
; When there are no numbers to display callee passing -1 to readLine()
; as a number of lines to display
    cmp qword [rbx+8], -1
    je bufferLoop

checkLines:
    cmp r15, qword [rbx+8]              ; end function when we've reached number of
    jae readEnd                        ; lines to display

; Read single character from file and save it in local variable
bufferLoop:
    mov rax, SYS_read
    mov rdi, qword [rbx]
    mov rsi, r13
    mov rdx, 1
    syscall

; check if operation was successful
    cmp rax, EISDIR
    je readEnd

    cmp rax, 0
    je readEnd
    
; Saving data in the buffer
    mov r10b, byte [r13]
    mov byte [r14+r12], r10b           ; buffer[i] = char;
    inc r12                            ; i++;

; When buffer is full or contains a newline, display buffer contents
    cmp r12, BUFFSIZE
    je printBuffer
    cmp r10b, LF
    je printBuffer

    jmp readLoop

; Display buffer contents on STDOUT (screen)
printBuffer:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, r14
    mov rdx, r12
    syscall

    mov r12, 0
    inc r15
    jmp readLoop

; Function end. Reset stack.
readEnd:
    pop rdx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret