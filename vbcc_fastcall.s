/* Thunks for vbcc's -fastcall builds.
 *
 * With -fastcall vbcc gives C symbols an @ prefix, and it applies that to the
 * calls it generates to its own runtime as well. For the 32-bit divide helper
 * it does so inconsistently: division emits "jsr @_divu" while modulo emits
 * "jsr __divu", so both names get referenced from the same object. vc.lib is
 * built with the default convention and provides only the plain one.
 *
 * The calling convention is identical either way: dividend in d0, divisor in
 * d1, quotient returned in d0 and remainder in d1. Verified by compiling the
 * same division with and without -fastcall and comparing the call sequences.
 * So the @-prefixed names only need forwarding to vc.lib's routines, and no
 * division has to be reimplemented.
 */

	.globl	@_divu
	.globl	@_divs

@_divu:
	jmp	__divu

@_divs:
	jmp	__divs
