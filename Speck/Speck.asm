; Speck 128/256 Cipher in x86-64
;
; The code is made public using
; the MIT License
;
; Author: Yash Gupta and James Hughes
;
; Build Instructions
;   nasm -f elf64 -g -F dwarf Speck.asm
;   ld -o Speck Speck.o

; -----------------------------------------------------------------------------;
;                 This section contains the initialized data                   ;
; -----------------------------------------------------------------------------;
section .data
    n: equ 64
    m: equ 4

    ; Number of Rounds
    T: equ 34

    ; Alpha and Beta rotate values
    alpha: equ 8
    beta:  equ 3

    ; Plain Text
    x: dq 0x65736f6874206e49
    lenx: equ $-x
    y: dq 0x202e72656e6f6f70
    len: equ $-x

    ; Key
    key: dq 0x1f1e1d1c1b1a1918, 0x1716151413121110, 0x0f0e0d0c0b0a0908
         dq 0x0706050403020100

    ; Output Messages
    msg1: db "Plaintext: "
    m1Len: equ $-msg1

    msg2: db "Ciphertext: "
    m2Len: equ $-msg2

    newLine: db 10

; -----------------------------------------------------------------------------;
;                     This section contains the code                           ;
; -----------------------------------------------------------------------------;
section .text:
    global _start

_start:
        nop                     ; Keeps GDb Happy!

; Output the plain text to the screen
        mov     rcx, msg1       ; Display helpful message
        mov     rdx, m1Len      ; Length of message
        call    Write           ; Display Now
        mov     rcx, x          ; Pass location of plaintext
        mov     rdx, len        ; Pass size of ciphertext
        call    Write           ; Display now
        mov     rcx, newLine    ; Add a new line
        mov     rdx, 1          ; New Line is one byte
        call    Write           ; Display now

Exit:
        mov     rax, 1          ; Service dispathcer uses 1 as sys_exit
        xor     rbx, rbx        ; RBX hld the return value. Returning -> 0
        int     0x80            ; Cause system interrupt

; Procedure to write data to stdout
Write:
        mov     rax, 4          ; Service dispatcher uses 4 as sys_write
        mov     rbx, 1          ; RBX holds the output stream. STDOUT is 1
        int     0x80            ; Cause system interrupt
        ret                     ; Return to caller

; Procedure to expand Keys
expKey:
        ret                     ; Return to caller

; Procedure to encrpty for one round
encRound:
        ret                     ; Return to caller

encrypt:
        ret                     ; Return to caller

; -----------------------------------------------------------------------------;
;                This section contains the uninitialized data                  ;
; -----------------------------------------------------------------------------;
section .bss
    ; No uninitialized data
