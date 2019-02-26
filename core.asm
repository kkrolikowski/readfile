; core.asm -- includes basic universal functions for string manipulations
; ------------------------------------------------------------------------

section .data

; -----
; Constants

NULL                equ 0
SYS_write           equ 1
STDOUT              equ 1

section .text

; -----
; prints() -- prints given string on  the screen
; HLL call: prints(string);
; Arguments:
;   1) string (rdi)
; Returns:
;   nothing

global prints
prints:
    push rbx

    mov rbx, rdi
    mov rdx, 0
; First we need to count characers we want to print
; so we will increment tho counter untill NULL character
; is encountered
CountLoop:
    cmp byte [rbx], NULL
    je CountDone
    inc rbx
    inc rdx
    jmp CountLoop

CountDone:
    cmp rdx, 0                      ; if we have nothing to print
    je printDone                    ; we can go to the end

; Now we can print whole string. RDX register was set during
; counting loop
    mov rax, SYS_write
    mov rsi, rdi
    mov rdi, STDOUT
    syscall

printDone:
    pop rbx
    ret

; -----
; s2int() -- converts string into integer
; HLL call: num = s2int(string);
; Arguments:
;   1) string, (RDI)
; Returns:
;   int number on success
;   -1: on negative string
;   -2: on invalid string

global s2int
s2int:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    push rcx
    push rbx
    push r11
    push r12

    mov rbx, rdi                        ; save string address
    lea rcx, qword [rbp-8]              ; number to return

; We want to eliminate negative numbers and those which
; starts with 0. 0-numbers are marked as invalid
    cmp byte [rbx], "-"
    je NegativeError
    cmp byte [rbx], "0"
    je InvalidString

    mov r8, 1                           ; actual divisior
    mov r9, 10                          ; divisior factor
    mov r10, 0                          ; characters on stack
    mov r11, 0                          ; characters from stack
    mov r12, 0                          ; integer to return

; the only purpose of this loop is validate whole string before
; we will push the values on the stack. It's because stack state
; will be more predictible. We need to be sure, that we are dealing
; with 0-9 characters.
VerifyLoop:
    cmp byte [rbx], NULL
    je PushNum
    cmp byte [rbx], "0"
    jb InvalidString
    cmp byte [rbx], "9"
    ja InvalidString

    inc rbx
    jmp VerifyLoop

PushNum:
    mov rbx, rdi                        ; once again we have to set string pointer

; Now we can proceed with pushing characters on stack untill NULL is encountered.
PushNumLoop:
    cmp byte [rbx], NULL
    je MakeNum
    mov al, byte [rbx]
    push rax

    inc rbx
    inc r10
    jmp PushNumLoop

; Conversion algorithm:
;   1) get character from stack
;   2) subtract 48 from character value to get integer value
;   3) multiple by factor.
;   4) update factor: factor  = factor * 10
;   5) sum = sum + new_val
;   5) if number of stack values is greater than those poped from stack
;       continue with loop, otherwise end loop
; Example:
;   123 = 3*1 + 2*10 + 1*100
MakeNum:
    pop rax
    inc r11
    sub al, 48
    
    cmp al, 0
    je MakeNumLoop

    mov edx, 0
    mul r8d
    mov dword [rcx], eax
    mov dword [rcx+4], edx
    add r12, qword [rcx]

MakeNumLoop:
    cmp r11, r10
    je s2intSuccess
    mov rax, r8
    mul r9
    mov r8, rax

    pop rax
    inc r11
    sub al, 48
    
    cmp al, 0
    je MakeNumLoop

    mov edx, 0
    mul r8d
    mov dword [rcx], eax
    mov dword [rcx+4], edx
    add r12, qword [rcx]
    jmp MakeNumLoop

s2intSuccess:
    mov rax, r12
    jmp s2intEnd
NegativeError:
    mov rax, -1
    jmp s2intEnd
InvalidString:
    mov rax, -2

s2intEnd:
    pop r12
    pop r11
    pop rbx
    pop rcx
    mov rsp, rbp
    pop rbp
    ret