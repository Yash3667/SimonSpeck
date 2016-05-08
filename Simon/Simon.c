# include	<stdint.h>
# include	<stdio.h>

void R(uint64_t* k, uint64_t* x, uint64_t* y);

int main(int argc, char* argv){}

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
		/* (S1x & S8x) */
		"mov	%1, %%rax \n\t"		// Load tmp into rax
		"rol	$1, %%rax \n\t" 	// S1x on rax
		"mov	%1, %%rbx \n\t" 	// Load tmp into rbx
		"rol	$8, %%rbx \n\t"		// S8x on rbx
		"and	%%rbx, %%rax \n\t"	//AND into rax
		/* (S1x & S8x) ^ S2x */
		"mov	%1, %%rbx \n\t"		// Load tmp into rbx
		"rol	$2, %%rbx \n\t" 	// S2x on rbx
		"xor	%%rbx, %%rax \n\t"	// XOR into rax
		/* XOR with current value of x */
		"mov	%2, %%rbx \n\t"		// Load x into rbx
		"xor	%%rbx, %%rax \n\t"	// XOR into rax
		"mov	%%rax, %0"			// Save into x
		: "=r" (*x)
		: "r" (tmp), "r" (*x)
		: "rax", "rbx"
		);

	*y = tmp;
}