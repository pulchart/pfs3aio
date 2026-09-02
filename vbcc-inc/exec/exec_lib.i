/* Minimal exec LVO set for the vbcc build of startup.s.
 * The NDK exec_lib.i is written for a Motorola-syntax assembler and needs the
 * FUNCDEF macro, which vasm's GNU-syntax mode does not provide. startup.s
 * references only these six.
 * Values follow from FUNCDEF order in the NDK exec_lib.i: first -30, step -6.
 */
	.set _LVODisable,-120
	.set _LVOEnable,-126
	.set _LVOAllocMem,-198
	.set _LVOFreeMem,-210
	.set _LVOFindTask,-294
	.set _LVOStackSwap,-732
