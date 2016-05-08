### Simon

Simon is implemented using a mixture of C and inline x86 assembly. The inline assembly greatly optimizes certain commands which are not natively supported in C (most notably, left circular shift).

The compiler used is GCC.

### Sizes 

We are implementing Simon 128/256. The notation represents Speck 2n/mn, where '2n' represents block size and 'mn' represents the key size. We choose 'n' as 64 bits, and hence, our block size is 128 bits. Our 'm' is 4, and hence, our key size is 256 bits. 
