; Speck 128/256 Cipher in x86-64          ;
;                                         ;
; The code is made public using           ;
; the MIT License                         ;
;                                         ;
; Author: Yash Gupta and James Hughes     ;
;                                         ;
; Build Instructions                      ;
;   nasm -f elf64 -g -F dwarf Speck.asm   ;
;   ld -o Speck Speck.o                   ;
;-----------------------------------------;

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
    y: dq 0x202e72656e6f6f70
    len: equ $-x

    ; Key
    key: dq 0x1f1e1d1c1b1a1918, 0x1716151413121110, 0x0f0e0d0c0b0a0908, 0x0706050403020100

    ; Output Messages
    msg1: db "Plaintext: "
    m1Len: equ $-msg1

    msg2: db "Ciphertext: "
    m2Len: equ $-msg2

    newLine: db 10

; -----------------------------------------------------------------------------;
;                This section contains the uninitialized data                  ;
; -----------------------------------------------------------------------------;
section .bss
    ; These are used in expand key procedure
    l: resq 38
    k: resq 34

; -----------------------------------------------------------------------------;
;                     This section contains the code                           ;
; -----------------------------------------------------------------------------;
section .text
    global _start

_start:
        nop                     ; Keeps GDb Happy!

; Output the plain text to the screen
        mov     rcx, msg1       ; Display helpful message
        mov     rdx, m1Len      ; Length of message
        call    Write           ; Display Now
        mov     rcx, x          ; Pass location of plaintext
        mov     rdx, len        ; Pass size of entire plaintext
        call    Write           ; Display now
        mov     rcx, newLine    ; Add a new line
        mov     rdx, 1          ; New Line is one byte
        call    Write           ; Display now

; Expand the keys and encrypt the plaintext
        call    expKey          ; Expand the keys according to Speck algorithm
        call    encrypt         ; Encrypt the plain text

; Test the first 4 Keys
        mov     rcx, [k]
        mov     rcx, [k + 8]
        mov     rcx, [k + 16]
        mov     rcx, [k + 24]

; Decrypt the cipher text
        call    decrypt            ; Decrypt the cipher text

; Test the block. Should be same as the one initialized in .data
        mov     rcx, [x]
        mov     rcx, [y]

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

;-------------------------------------------------------------------------------
; Procedure to expand Keys
; Registers Used: RAX, RBX, RCX, RDX, RBP, RSI, RDI
;
; The following assembly is a translation of :-
; -------------------------------------------------------;
; k[0] = key[3]                                          ;
;                                                        ;
; l[0] = key[2]                                          ;
; l[1] = key[1]                                          ;
; l[2] = key[0]                                          ;
;                                                        ;
; for i := 0; i < T-1; i++ {                             ;
;   l[i+m-1], k[i+1] = encryptRound(uint64(i),l[i],k[i]) ;
; }                                                      ;
; return k                                               ;
;--------------------------------------------------------;
;
; 'l' and 'k' are global variables in this assembly
; rather than local variables. Hence, I am not returning
; any specific value
expKey:
; k[0] = key[3]
        mov     rax, [key + 24] ; Move the last qword into RAX
        mov     [k], rax        ; Move the last qword into the first slot of k

; l[0] = key[2]
; l[1] = key[1]
; l[2] = key[0]
        mov     rax, [key + 16] ; Move the third qword into RAX
        mov     [l], rax        ; Move it into the first slot of l
        mov     rax, [key + 8]  ; Move the second qword into RAX
        mov     [l + 8], rax    ; Move it into the second slot of l
        mov     rax, [key]      ; Move the first qword into RAX
        mov     [l + 16], rax   ; Move it into the third slot of l

; for i := 0; i < T-1; i++ {
; 	l[i+m-1], k[i+1] = encryptRound(uint64(i),l[i],k[i])
; }
;
; RSI will maintain offset for l
; RBP will maintain offset for k
; RDI will hold the maximum number of iterations (# of Rounds - 1)
        xor     rcx, rcx        ; RCX will maintain the count
        lea     rdi, [T - 1]    ; Max iteration is one less than T
        lea     rsi, [m - 1]    ; RSI will maintain the offset for l
        lea     rbp, [rcx + 1]  ; RBP will maintain the offset for k.
                                ; Using lea in above instruction for consistency
.keyLoop:
; RBX will hold the value for l.
; RDX will hold the value for k
        mov     rbx, [l + rcx*8]  ; RBX holds the value for l
        mov     rdx, [k + rcx*8]  ; RDX holds the value for k
        call    encRound          ; Apply the rotations specified in the algorithm
        mov     [l + rsi*8], rbx  ; Save this value of RBX into l
        mov     [k + rbp*8], rdx  ; Save this value of RDX into k

; Prepare for next iteration of the loop
        inc     rsi             ; Increment the offset for l
        inc     rbp             ; Increment the offset for k
        inc     rcx             ; Increment RCX for next iteration
        cmp     rcx, rdi        ; Check RCX for max iterations...
        jne     .keyLoop        ; ...and jump to next iteration if not

; Key expansion is over now. Safe to return
        ret                     ; Return to caller
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Procedure to do rotations/encryption per round
; Registers Used: RBX, RCX, RDX
;
; The following assembly is a tranlsation of :-
; ---------------------------------------------------------------;
; encryptRound(k uint64, x uint64, y uint64) (uint64, uint64) {  ;
;   x = (rotR(x, alpha) + y) ^ k                                 ;
;   y = rotL(y, beta) ^ x                                        ;
;   return x, y                                                  ;
; }                                                              ;
; ---------------------------------------------------------------;
;
; Parameter translation
; -> k: RCX
; -> x: RBX
; -> y: RDX
;
; RBX and RDX are the registers which will be acted upon. Hence
; no specific value is being returned.
encRound:
; x = (rotR(x, alpha) + y) ^ k
        ror     rbx, alpha      ; Rotate RBX right by alpha
        add     rbx, rdx        ; Add RDX to RBX
        xor     rbx, rcx        ; Finally, XOR RBX with RCX

; y = rotL(y, beta) ^ x
        rol    rdx, beta        ; Rotate RDX left by beta
        xor    rdx, rbx         ; XOR RDX with RBX

; Round rotation/encryption over. Safe to return
        ret                     ; Return to caller
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Procedure to encrypt the plaintext into ciphertext
; Registers Used: RAX, RBX, RCX, RDX, RDI
;
; The following assembly is a translation of :-
;--------------------------------------------------;
; for i := 0 i < T; i++ {                          ;
;   x, y = encryptRound(k[i], x, y)                ;
; }                                                ;
;--------------------------------------------------;
;
; The encryption procedure using the same rotations
; as the key expansion.
encrypt:
; This time RAX will maintain loop count
; as RCX will need to hold the round key
        xor     rax, rax        ; RAX will maintain count of the loop
        mov     rdi, T          ; The loop needs to run for the # of rounds
.eLoop:
; RCX will hold the key for this round
; RBX holds the higher 64 bits of the block
; RDX holds the lower 64 bits of the block
        mov     rcx, [k + rax*8]; Move this rounds key into RCX
        mov     rbx, [x]        ; Move higher 64 bits into RBX
        mov     rdx, [y]        ; Move lower 64 bits into RDX
        call    encRound        ; Encrypt the plaintext using the algorithm
        mov     [x], rbx        ; Save this value of RBX into x
        mov     [y], rdx        ; Save this value of RDX into y

; Prepare for next iteration of the loop
        inc     rax             ; Increment RAX for next iteration
        cmp     rax, rdi        ; Compare with # of rounds...
        jne     .eLoop          ; ...and iterate again if not equal

; Encryption over. Safe to return
        ret                     ; Return to caller
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Procedure to do decryption per round
; Registers Used: RBX, RCX, RDX
;
; The following assembly is a tranlsation of :-
; ---------------------------------------------------------------;
; decryptRound(k uint64, x uint64, y uint64) (uint64, uint64) {  ;
;   y = rotR(y ^ x, beta)                                        ;
;   x = rotL((x ^ k) - y, alpha)                                 ;
;   return x, y                                                  ;
; }                                                              ;
; ---------------------------------------------------------------;
;
; Parameter translation
; -> k: RCX
; -> x: RBX
; -> y: RDX
;
; RBX and RDX are the registers which will be acted upon. Hence
; no specific value is being returned.
decRound:
; y = rotR(y ^ x, beta)
        xor     rdx, rbx        ; XOR RDX with RBX
        ror     rdx, beta       ; Rotate RDX to the right by beta

; x = rotL((x ^ k) - y, alpha)
        xor    rbx, rcx         ; XOR RBX with RCX
        sub    rbx, rdx         ; Subtract RDX from RBX
        rol    rbx, alpha       ; Rotate RBX to the left by alpha

; Round decryption over. Safe to return
        ret                     ; Return to caller
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Procedure to decrypt ciphertext to plaintext
; Registers Used:
;
; The following assembly is a translation of :-
;---------------------------------------------;
; for i := 0; i < T; i++ {                    ;
;   x, y = decryptRound(k[T-i-1],x,y)         ;
; }                                           ;
;---------------------------------------------;
;
; The decrpytion procedure is different from the
; encryption procedure by the order of the key
; passed.
decrypt:
; RAX will maintain loop count
; RSI will be used to hold key index
; RCX will be used to hold key
        xor     rax, rax        ; RAX will hold loop count
        lea     rsi, [T - 1]    ; RSI will hold key index
        mov     rdi, T          ; Loop needs be run for the # of rounds
.dLoop:
; RCX will hold the key for this round
; RBX holds the higher 64 bits of the block
; RDX holds the lower 64 bits of the block
        mov     rcx, [k + rsi*8]; Hold the key for this round
        mov     rbx, [x]        ; RBX holds higher 64 bits of cipher text
        mov     rdx, [y]        ; RDX holds lower 64 bits of cipher text
        call    decRound        ; Decrypt using the algorithm
        mov     [x], rbx        ; Save this value of RBX into x
        mov     [y], rdx        ; Save this value of RDX into y

; Prepare for the next iteration of the loop
        dec     rsi             ; Lower the index for the next round
        inc     rax             ; Increment RAX for the next iteration
        cmp     rax, rdi        ; Compare with # of rounds...
        jne     .dLoop          ; ...and iterate again if not equal

; Decryption Over. Safe to return
        ret                     ; Return to caller
;-------------------------------------------------------------------------------
