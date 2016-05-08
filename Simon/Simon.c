/*
 * Simon 128/256 Cipher in C and inline assembly
 *
 * This code is made public using the MIT License
 *
 * Author: Justin Raizes
 */

 # include	"Simon.h"

/*
 * A basic Simon round.
 */
void R(uint64_t* k, uint64_t* x, uint64_t* y){
	// Save x
	uint64_t tmp = *x;

	*x = *y ^ *k;

	/*	Compute f(x) = (S1x & S8x) ^ S2x, using the
		original value of x (saved by tmp), where Sax 
		left circlular shifts x by a. 
		Then, XOR it with the current value of x.

		Inline assembly speeds up the circular shift,
		which is not natively supported in c.
	 */
	asm(
		/* Load the original value of x into rax, rbx, rcx */
		"mov	%1, %%rax \n\t"
		"mov	%%rax, %%rbx \n\t"
		"mov	%%rax, %%rcx \n\t"

		/* Compute (S1x & S8x) */
		"rol	$1, %%rax \n\t"
		"rol	$8, %%rbx \n\t"
		"and	%%rbx, %%rax \n\t"

		/* Compute (S1x & S8x) ^ S2x */
		"rol	$2, %%rcx \n\t"
		"XOR	%%rcx, %%rax \n\t"

		/* XOR with current value of x and save */
		"mov	%2, %%rbx \n\t"
		"xor	%%rbx, %%rax \n\t"
		"mov	%%rax, %0"

		:"=r" (*x)
		:"r" (tmp), "r" (*x)
		: "rax", "rbx", "rcx"
		);

	*y = tmp;
}