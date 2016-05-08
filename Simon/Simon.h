# include	<stdint.h>

/* 11010001111001101011011000100000010111000011001010010011101111 
   encoded as an integer.
 */
# define	Z4	3781244162168104175
# define	GETBIT(num, i)	((num >> i) & 01)

/* T is the number of rounds */
# define	T	72
/* c is used in key expansion */
# define	c	18446744073709551612



void R(uint64_t* k, uint64_t* x, uint64_t* y);
uint64_t* keyExpansion(uint64_t* k);