/* LIVE @src vbcc_compat.c @func memmove */

/* Runs the memmove from vbcc_compat.c on an emulated 68k and compares it
 * against an obviously-correct byte reference, over every small length at
 * every overlap offset in both directions plus a pseudo-random sweep.
 *
 * tests/live/memmove_live.c checks the same function on the host, which is
 * quicker but cannot see target type widths, target alignment behaviour, or an
 * assembly implementation. This one can, which is what makes an assembly
 * variant reviewable at all.
 *
 *   sh tests/m68k/run.sh
 */

#include <exec/types.h>	/* the real ULONG and UWORD widths, not stand-ins */
#include <stdio.h>

/* the function under test, lifted from the driver source */
#define memmove pfs_memmove
#include "gen/memmove.c"
#undef memmove

/* reference: byte at a time, direction chosen the only way it can be */
static void ref_memmove(unsigned char *d, const unsigned char *s, unsigned long n)
{
	unsigned long i;

	if (d == s || n == 0)
		return;
	if (d < s) {
		for (i = 0; i < n; i++)
			d[i] = s[i];
	} else {
		for (i = n; i > 0; i--)
			d[i - 1] = s[i - 1];
	}
}

#define BUF 800
#define BASE 200

static unsigned char a[BUF], b[BUF];

static int one(int off, int len)
{
	int i;

	for (i = 0; i < BUF; i++)
		a[i] = b[i] = (unsigned char)(i * 7 + 1);

	pfs_memmove(a + BASE + off, a + BASE, (unsigned long)len);
	ref_memmove(b + BASE + off, b + BASE, (unsigned long)len);

	for (i = 0; i < BUF; i++) {
		if (a[i] != b[i])
			return 0;
	}
	return 1;
}

int main(void)
{
	int off, len, i, cases = 0, fails = 0;
	unsigned long seed = 12345;

	for (len = 0; len <= 40; len++) {
		for (off = -40; off <= 40; off++) {
			cases++;
			if (!one(off, len)) {
				if (fails < 5)
					printf("  MISMATCH len=%d off=%d\n", len, off);
				fails++;
			}
		}
	}

	/* larger, the directory-block shape, including unaligned ends */
	for (i = 0; i < 4000; i++) {
		seed = seed * 1103515245UL + 12345UL;
		len = (int)((seed >> 8) % 380);
		seed = seed * 1103515245UL + 12345UL;
		off = (int)((seed >> 8) % 81) - 40;
		cases++;
		if (!one(off, len)) {
			if (fails < 5)
				printf("  MISMATCH random len=%d off=%d\n", len, off);
			fails++;
		}
	}

	printf("  %d cases, %d mismatches\n", cases, fails);
	if (fails == 0) {
		printf("  PASS: memmove matches the byte reference on 68k\n");
		return 0;
	}
	return 1;
}
