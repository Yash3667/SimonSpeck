# include	<stdint.h>

/* 11010001111001101011011000100000010111000011001010010011101111 
   encoded as an integer.
 */
# define	Z4	3781244162168104175
# define	GETBIT(num, i)	((num >> (61 - i)) & 01)

/* T is the number of rounds */
# define	T	72

uint64_t* keyExpansion(uint64_t* k);

void encrypt(uint64_t* plaintext, uint64_t* key, int len);
void R(uint64_t* k, uint64_t* x, uint64_t* y);

void decrypt(uint64_t* plaintext, uint64_t* key, int len);
void Rinv(uint64_t* k, uint64_t* x, uint64_t* y);