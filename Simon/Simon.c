/*
 * Simon 128/256 Cipher in C and inline assembly
 *
 * This code is made public using the MIT License
 *
 * Author: Justin Raizes
 */

# include	"Simon.h"


void encrypt(uint64_t* plaintext, uint64_t* key, int len){
	int i, j;

	for (i = 0; i < len - 1; i += 2){
		for (j = 0; j < T; j++){
			R(key + j, plaintext + i, plaintext + i + 1);
		}
	}
}

void decrypt(uint64_t* plaintext, uint64_t* key, int len){
	int i, j;

	for (i = 0; i < len - 1; i += 2){
		for (j = T - 1; j >= 0; j--){
			Rinv(key + j, plaintext + i, plaintext + i + 1);
		}
	}
}


/*
 * Key expansion for the Simon block cipher.
 *
 * k should be of length T (defined in Simon.h).
 * Modifies the values at k.
 */
uint64_t* keyExpansion(uint64_t* k){
	int i;
	uint64_t tmp;

	/* Reverse the order of k */
	for (i = 0; i < 2; i++){
		tmp = k[i];
		k[i] = k[3 - i];
		k[3 - i] = tmp;
	}

	for (i = 4; i < T; i++){
		/*	Inline assembly speeds up the circular shift,
			which is not natively supported in c.
		 */
		asm __volatile__(
			/* Save S(-3)k[i - 1] into a register */
			"mov	%1, %%rax \n\t"
			"rol	$-3, %%rax \n\t"
			/* XOR that reg with k[i - 3] */
			"xor	%2, %%rax \n\t"
			/* XOR that reg with itself S(-1) */
			"mov	%%rax, %%rbx \n\t"
			"rol	$-1, %%rbx \n\t"
			"xor	%%rbx, %%rax \n\t"
			/* Save into tmp */
			"mov	%%rax, %0"
			: "=r" (tmp)
			: "r" (k[i - 1]), "r" (k[i - 3])
			: "rax", "rbx"
			);
		k[i] = ~k[i - 4] ^ tmp ^ GETBIT(Z4, (i - 4) % 62) ^ 3;
	}
}


/*
 * A basic Simon round. 
 * Modifies the values at x and y.
 */
void R(uint64_t* k, uint64_t* x, uint64_t* y){
	// Save x
	uint64_t tmp = *x;

	*x = *y;

	/*	Compute f(x) = (S1x & S8x) ^ S2x, using the
		original value of x (saved by tmp), where Sax 
		left circlular shifts x by a. 
		Then, XOR it with the current value of x.

		Inline assembly speeds up the circular shift,
		which is not natively supported in c.
	 */
	asm __volatile__(
		/* Load the original value at x into rax, rbx, rcx */
		"mov	%1, %%rax \n\t"
		"mov	%%rax, %%rbx \n\t"
		"mov	%%rax, %%rcx \n\t"

		/* Compute (S1x & S8x) */
		"rol	$1, %%rax \n\t"
		"rol	$8, %%rbx \n\t"
		"and	%%rbx, %%rax \n\t"

		/* Compute (S1x & S8x) ^ S2x */
		"rol	$2, %%rcx \n\t"
		"xor	%%rcx, %%rax \n\t"

		/* XOR with the previous changes to *x and save */
		"mov	%2, %%rbx \n\t"
		"xor	%%rbx, %%rax \n\t"
		"mov	%%rax, %0"

		:"=r" (*x)
		:"r" (tmp), "r" (*x)
		: "rax", "rbx", "rcx"
		);

	*x ^= *k;

	*y = tmp;
}

void Rinv(uint64_t* k, uint64_t* x, uint64_t* y){
	// Save y
	uint64_t tmp = *y;

	*y = *x ^ *k;

	/*	Compute f(y) = (S1x & S8y) ^ S2y, using the
		original value of y (saved by tmp), where Sax 
		left circlular shifts y by a. 
		Then, XOR it with the current value of y.

		Inline assembly speeds up the circular shift,
		which is not natively supported in c.
	 */
	asm __volatile__(
		/* Load the original value at y into rax, rbx, rcx */
		"mov	%1, %%rax \n\t"
		"mov	%%rax, %%rbx \n\t"
		"mov	%%rax, %%rcx \n\t"

		/* Compute (S1x & S8x) */
		"rol	$1, %%rax \n\t"
		"rol	$8, %%rbx \n\t"
		"and	%%rbx, %%rax \n\t"

		/* Compute (S1x & S8x) ^ S2x */
		"rol	$2, %%rcx \n\t"
		"xor	%%rcx, %%rax \n\t"

		/* XOR with the previous changes to *y and save */
		"mov	%2, %%rbx \n\t"
		"xor	%%rbx, %%rax \n\t"
		"mov	%%rax, %0"

		:"=r" (*y)
		:"r" (tmp), "r" (*y)
		: "rax", "rbx", "rcx"
		);

	*x = tmp;
}