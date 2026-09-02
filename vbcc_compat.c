/* Implementations for functions this tree expects from the compiler's runtime
 * but vbcc does not provide. Only built by the vbcc tier; see TOOLCHAINS.md.
 */

#include <exec/types.h>
#include <string.h>	/* size_t, and the prototypes these must match */
#include "vbcc_compat.h"

#if defined(__VBCC__)

/* Case-insensitive string compare, used by directory.c. gcc gets this from
 * libnix; vbcc's vc.lib has no equivalent.
 */
int stricmp(const char *a, const char *b)
{
	unsigned char ca, cb;

	for (;;) {
		ca = (unsigned char)*a++;
		cb = (unsigned char)*b++;
		if (ca >= 'A' && ca <= 'Z') ca += 'a' - 'A';
		if (cb >= 'A' && cb <= 'Z') cb += 'a' - 'A';
		if (ca != cb)
			return (int)ca - (int)cb;
		if (ca == 0)
			return 0;
	}
}

/* With -fastcall every symbol gets an @ prefix, including calls the compiler
 * generates to its own runtime. vc.lib is built with the default convention,
 * so those calls go unresolved and the routines have to be supplied here.
 * Only the four below are needed; the divide helpers are not, because the
 * fastcall tier is 68020+ where divu.l/divs.l are hardware instructions.
 *
 * That is also why -fastcall is not used on the 68000+ tier: there the
 * compiler needs _divu/_divs, and those return the quotient in d0 *and* the
 * remainder in d1 (the modulo path reads d1), which cannot be expressed as a
 * C function. Supplying them would mean hand-written assembly.
 */
#if defined(PFS_FASTCALL)

char *strchr(const char *s, int c)
{
	unsigned char ch = (unsigned char)c;

	for (;; s++) {
		if ((unsigned char)*s == ch)
			return (char *)s;
		if (*s == 0)
			return 0;
	}
}

int memcmp(const void *a, const void *b, size_t n)
{
	const unsigned char *p = a, *q = b;

	for (; n > 0; n--, p++, q++) {
		if (*p != *q)
			return (int)*p - (int)*q;
	}
	return 0;
}

/* Copies in longwords where both pointers allow it, then words, then bytes.
 * directory.c shifts whole directory blocks through this when adding or
 * removing entries, up to the reserved block size, so a byte loop is wasteful:
 * vbcc compiles one into seven instructions per byte.
 * Uses ULONG/UWORD for the copies rather than long/short on purpose: the
 * widths have to be exactly 4 and 2 bytes, which long is not on a 64-bit host,
 * and the test below runs there. size_t is used for the alignment casts, being
 * pointer-sized on both.
 * Correctness is checked against the host memmove by tests/live/memmove_live.c.
 */
void *memmove(void *d, const void *s, size_t n)
{
	unsigned char *dp = d;
	const unsigned char *sp = s;

	if (dp == sp || n == 0)
		return d;

	if (dp < sp) {
		/* forward: align the destination, then bulk copy, then tail */
		while (n > 0 && ((size_t)dp & 1)) {
			*dp++ = *sp++;
			n--;
		}
		if ((((size_t)dp | (size_t)sp) & 3) == 0) {
			while (n >= 32) {	/* unrolled, as libnix's __bcopz is */
				((ULONG *)dp)[0] = ((const ULONG *)sp)[0];
				((ULONG *)dp)[1] = ((const ULONG *)sp)[1];
				((ULONG *)dp)[2] = ((const ULONG *)sp)[2];
				((ULONG *)dp)[3] = ((const ULONG *)sp)[3];
				((ULONG *)dp)[4] = ((const ULONG *)sp)[4];
				((ULONG *)dp)[5] = ((const ULONG *)sp)[5];
				((ULONG *)dp)[6] = ((const ULONG *)sp)[6];
				((ULONG *)dp)[7] = ((const ULONG *)sp)[7];
				dp += 32; sp += 32; n -= 32;
			}
			while (n >= 4) {
				*(ULONG *)dp = *(const ULONG *)sp;
				dp += 4; sp += 4; n -= 4;
			}
		}
		if ((((size_t)dp | (size_t)sp) & 1) == 0) {
			while (n >= 2) {
				*(UWORD *)dp = *(const UWORD *)sp;
				dp += 2; sp += 2; n -= 2;
			}
		}
		while (n-- > 0)
			*dp++ = *sp++;
	} else {
		/* backward, from the far end */
		dp += n;
		sp += n;
		while (n > 0 && ((size_t)dp & 1)) {
			*--dp = *--sp;
			n--;
		}
		if ((((size_t)dp | (size_t)sp) & 3) == 0) {
			while (n >= 32) {
				dp -= 32; sp -= 32; n -= 32;
				((ULONG *)dp)[7] = ((const ULONG *)sp)[7];
				((ULONG *)dp)[6] = ((const ULONG *)sp)[6];
				((ULONG *)dp)[5] = ((const ULONG *)sp)[5];
				((ULONG *)dp)[4] = ((const ULONG *)sp)[4];
				((ULONG *)dp)[3] = ((const ULONG *)sp)[3];
				((ULONG *)dp)[2] = ((const ULONG *)sp)[2];
				((ULONG *)dp)[1] = ((const ULONG *)sp)[1];
				((ULONG *)dp)[0] = ((const ULONG *)sp)[0];
			}
			while (n >= 4) {
				dp -= 4; sp -= 4; n -= 4;
				*(ULONG *)dp = *(const ULONG *)sp;
			}
		}
		if ((((size_t)dp | (size_t)sp) & 1) == 0) {
			while (n >= 2) {
				dp -= 2; sp -= 2; n -= 2;
				*(UWORD *)dp = *(const UWORD *)sp;
			}
		}
		while (n-- > 0)
			*--dp = *--sp;
	}
	return d;
}

size_t strcspn(const char *s, const char *reject)
{
	const char *p;
	size_t n = 0;

	for (; *s; s++, n++) {
		for (p = reject; *p; p++) {
			if (*s == *p)
				return n;
		}
	}
	return n;
}

#endif /* PFS_FASTCALL */

#endif /* __VBCC__ */
