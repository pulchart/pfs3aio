#!/bin/sh
# Static line-A audit: scans generated assembly for the 68080 instructions that
# encode in the A-line space.
#
#   sh tests/check-linea.sh <dir-of-.s-files> [label]
#
# A core outside scores 10280 to 10904 alerts 8000000A on them. Only the
# 68080la build is meant to have any.
#
# Not flagged: cmpiw.l, addiw.l and 64-bit mulu.l are 68080 only but outside
# the group. Reads assembly, not objdump, for the reason in check68060.sh.

set -u
DIR=${1:-}
LABEL=${2:-$DIR}

[ -n "$DIR" ] && [ -d "$DIR" ] || { echo "usage: $0 <dir-of-.s-files> [label]"; exit 2; }

set -- "$DIR"/*.s
[ -e "$1" ] || { echo "ERROR: no .s files in $DIR"; exit 2; }

clrq=$(grep -hcE '^[[:space:]]+clr\.q' "$@" | awk '{s+=$1} END{print s+0}')
mov3q=$(grep -hcE '^[[:space:]]+mov3q' "$@" | awk '{s+=$1} END{print s+0}')
moviw=$(grep -hcE '^[[:space:]]+moviw' "$@" | awk '{s+=$1} END{print s+0}')
mvsz=$(grep -hcE '^[[:space:]]+mv[sz]\.[bw]' "$@" | awk '{s+=$1} END{print s+0}')

# dbral is not line-A: it assembles to 51cf, an ordinary DBF, and only the
# counter width differs. Counted so a build says whether it has any.
dbral=$(grep -hcE '^[[:space:]]+dbral' "$@" | awk '{s+=$1} END{print s+0}')

total=$((clrq + mov3q + moviw + mvsz))

printf "%-16s clr.q=%-4s mov3q=%-4s moviw=%-4s mvs/mvz=%-4s (dbral=%-4s) %s\n" \
	"$LABEL" "$clrq" "$mov3q" "$moviw" "$mvsz" "$dbral" \
	"$([ "$total" -eq 0 ] && echo OK || echo LINE-A)"

if [ "$total" -ne 0 ]; then
	echo "  offending lines:"
	grep -hnE '^[[:space:]]+(clr\.q|mov3q|moviw|mv[sz]\.[bw])' "$@" \
		| sed 's/^/    /' | head -10
fi

[ "$total" -eq 0 ]
