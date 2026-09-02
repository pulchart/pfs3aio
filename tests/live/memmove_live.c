/* LIVE @src vbcc_compat.c @func memmove
 *
 * Lifts the memmove from vbcc_compat.c, which the vbcc builds use because
 * -fastcall makes vc.lib's version unreachable, and checks it against the
 * host's. Exhaustive over small sizes and every overlap offset, plus random
 * larger cases, since directory.c shifts whole directory blocks through it.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Stand-ins for the Amiga fixed-width types the lifted function uses. The
 * widths must match the target: ULONG 4 bytes, UWORD 2. size_t is only used
 * for alignment casts, so pointer-sized here is right.
 */
typedef unsigned int ULONG;
typedef unsigned short UWORD;

#define memmove pfs_memmove
#include "gen/memmove.c"
#undef memmove

#define BUF 600

int main(void)
{
	unsigned char a[BUF], b[BUF];
	int off, len, base, i, fails = 0, cases = 0;
	unsigned seed = 12345;

	/* every small length at every overlap offset, both directions */
	for (len = 0; len <= 40; len++) {
		for (off = -40; off <= 40; off++) {
			base = 200;
			for (i = 0; i < BUF; i++)
				a[i] = b[i] = (unsigned char)(i * 7 + 1);
			pfs_memmove(a + base + off, a + base, len);
			memmove(b + base + off, b + base, len);
			cases++;
			if (memcmp(a, b, BUF) != 0) {
				if (fails < 3)
					printf("  MISMATCH len=%d off=%d\n", len, off);
				fails++;
			}
		}
	}

	/* random larger cases, the directory-block shape */
	for (i = 0; i < 20000; i++) {
		seed = seed * 1103515245u + 12345u;
		len = (seed >> 8) % 400;
		seed = seed * 1103515245u + 12345u;
		off = (int)((seed >> 8) % 81) - 40;
		base = 100;
		for (int j = 0; j < BUF; j++)
			a[j] = b[j] = (unsigned char)(j * 13 + 5);
		pfs_memmove(a + base + off, a + base, len);
		memmove(b + base + off, b + base, len);
		cases++;
		if (memcmp(a, b, BUF) != 0) {
			if (fails < 3)
				printf("  MISMATCH random len=%d off=%d\n", len, off);
			fails++;
		}
	}

	printf("  %d cases, %d mismatches\n", cases, fails);
	if (fails == 0)
		printf("  PASS: memmove matches the host over overlaps and alignments\n");
	return fails != 0;
}
