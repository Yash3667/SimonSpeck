## Speck  

Speck is implemented using x86 - 64 Assembly. The assembler used is nasm. The Linux system calls are being handled using raw software interrupts (80H). The code WILL NOT work as procedures/function calls in C.  

### Sizes  

We are implementing Speck 128/256. The notation represents Speck 2n/mn, where '2n' represents block size and 'mn' represents the key size. We choose 'n' as 64 bits, and hence, our block size is 128 bits. Our 'm' is 4, and hence, our key size is 256 bits.  

### Code Convention

No Specific code convention is followed in the assembly code.
