# include	<stdio.h>
# include	<assert.h>

# include 	"Simon.h"


int main(int argc, char* argv){
	uint64_t text[2] = 	{8367809505449045871,
						 7883959205594428265 };

	uint64_t key[T] = 	{2242261671028070680,
						 1663540288323457296,
						 1084818905618843912,
						 506097522914230528 };

	printf("Key: %lx %lx %lx %lx\n", key[0], key[1], key[2], key[3]);
	printf("Plaintext: %lx %lx\n", text[0], text[1]);

	encrypt(text, key, 2);

	printf("Encrypted: %lx %lx \n", text[0], text[1]);

	printf("Expected:  8d2b5579afc8a3a0 3bf72a87efe7b868 \n");

	decrypt(text, key, 2);

	printf("Decrypted: %lx %lx \n", text[0], text[1]);
}
/*
well.... i can encrypt and decrypt.
the output isn't correct though
*/