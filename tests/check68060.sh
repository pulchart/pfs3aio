#!/bin/sh
# Static 68060 audit: scans generated assembly for the integer instructions the
# 68060 does not implement in hardware.
#
#   sh tests/check68060.sh <dir-of-.s-files> [label]
#
# The 68060 traps these and the 68060 software support package emulates them,
# but that is loaded from disk during boot. A filesystem in Kickstart ROM runs
# earlier, so anything on this list must not be generated at all.
#
# List from Motorola's "Porting software from an MC68040 to an MC68060":
# 64-bit DIVU.L/DIVS.L, 64-bit MULU.L/MULS.L, MOVEP, CHK2, CMP2, CAS2, and CAS
# with a misaligned effective address. Bitfield instructions are NOT on it.
#
# Reads assembly rather than objdump output on purpose: disassembling .text
# decodes switch jump tables as instructions and invents matches. That happened
# here, reporting two MOVEP in dostohandlerinterface.c that do not exist.

set -u
DIR=${1:-}
LABEL=${2:-$DIR}

[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "usage: $0 <dir-of-.s-files> [label]"; exit 2; }

set -- "$DIR"/*.s
[ -e "$1" ] || { echo "ERROR: no .s files in $DIR"; exit 2; }

# 64-bit forms are the ones naming two data registers as Dh:Dl
mul64=$(grep -hcE '^[[:space:]]+mul[su]\.l.*:%?d[0-7]' "$@" | awk '{s+=$1} END{print s+0}')
div64=$(grep -hcE '^[[:space:]]+div[su]\.l.*:%?d[0-7]' "$@" | awk '{s+=$1} END{print s+0}')
movep=$(grep -hcE '^[[:space:]]+movep' "$@" | awk '{s+=$1} END{print s+0}')
chk2=$(grep -hcE '^[[:space:]]+(chk2|cmp2)' "$@" | awk '{s+=$1} END{print s+0}')
cas2=$(grep -hcE '^[[:space:]]+cas2' "$@" | awk '{s+=$1} END{print s+0}')

total=$((mul64 + div64 + movep + chk2 + cas2))

printf "%-16s mul64=%-4s div64=%-4s movep=%-4s chk2/cmp2=%-4s cas2=%-4s %s\n" \
	"$LABEL" "$mul64" "$div64" "$movep" "$chk2" "$cas2" \
	"$([ "$total" -eq 0 ] && echo OK || echo UNSAFE)"

if [ "$total" -ne 0 ]; then
	echo "  offending lines:"
	grep -hnE '^[[:space:]]+(mul[su]\.l.*:%?d[0-7]|div[su]\.l.*:%?d[0-7]|movep|chk2|cmp2|cas2)' "$@" \
		| sed 's/^/    /' | head -10
fi

[ "$total" -eq 0 ]
