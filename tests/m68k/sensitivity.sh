#!/bin/sh
# Checks that driverbench responds to its knobs the way it should, by varying
# one at a time and running every configuration twice.
#
#   sh tests/m68k/sensitivity.sh [driver]
#
# A cycle count that does not move when the work changes is measuring the
# harness rather than the driver, which is how the earlier claim that reads do
# not reach the driver came about. This is the check that would have caught it.
# Expected, and what the measured slopes came out as:
#
#   directory entries   ls linear, 2708 and 2766 cycles per entry over the two
#                       intervals; create and rd grow more slowly; fmt and wr flat
#   payload bytes       wr linear, 1.422 cycles per byte in both intervals;
#                       rd linear, 0.097; fmt, ls and create flat
#   partition size      fmt linear, about 3000 cycles per MiB of partition;
#                       everything else flat
#
# rd growing with the entry count is not an error: a read has to find the file,
# and its slope of 208 to 391 cycles per entry is the same directory scan that
# shows up in create. It does mean the rd column carries a lookup component, and
# at the driverbench defaults a read is mostly neither: 51k cycles of transfer
# and 20k of scan against about 110k of fixed packet handling.

set -u
DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$DIR/../.." && pwd)
TMP=$ROOT/tests/.tmp
DRV=${1:-$ROOT/compare/gcc6/68020/pfs3aio}
CPU=${CPU:-68020}
BS=${BS:-512}

command -v rdbtool >/dev/null 2>&1 || { echo "ERROR: rdbtool not on PATH"; exit 2; }
[ -f "$DRV" ] || { echo "ERROR: no driver at $DRV"; exit 2; }
mkdir -p "$TMP"

cyc() {
	out=$(BENCH_CPU=$CPU python3 "$DIR"/driverbench.py "$@" --driver "$DRV" 2>&1 >/dev/null)
	n=$(printf '%s' "$out" | sed -n 's/.*cycles=\([0-9]*\).*/\1/p')
	rc=$(printf '%s' "$out" | sed -n 's/.*rc=\([0-9]*\).*/\1/p')
	if [ "$rc" = 0 ] && [ -n "$n" ]; then echo $((n / 1000)); else echo fail; fi
}

newimg() {
	rm -f "$1"
	rdbtool -f "$1" create size=$2 + init + add name=DH0 size=95% \
		dostype=0x50465303 bs=$BS >/dev/null 2>&1
}

measure() {	# $1=label $2=partition size $3=payload bytes $4=dir entries
	t=$TMP/sens-template.hdf
	newimg "$t" "$2"
	cyc format "$t" DH0 V >/dev/null
	head -c "$3" /dev/urandom > "$TMP/sens-pl.bin"
	cyc write "$t" --file F --in "$TMP/sens-pl.bin" >/dev/null
	i=0
	while [ "$i" -lt "$4" ]; do
		i=$((i + 1))
		cyc write "$t" --file "F$i" --in "$TMP/sens-small.bin" >/dev/null
	done
	for rep in 1 2; do
		img=$TMP/sens.hdf
		newimg "$img" "$2"
		f=$(cyc format "$img" DH0 V)
		w=$(cyc write "$img" --file F --in "$TMP/sens-pl.bin")
		cp "$t" "$img"
		r=$(cyc read "$img" --file F --out "$TMP/sens-back.bin")
		l=$(cyc ls "$img")
		c=$(cyc write "$img" --file NEXT --in "$TMP/sens-small.bin")
		printf "%-18s rep%d  fmt %-6s wr %-6s rd %-6s ls %-6s create %s\n" \
			"$1" "$rep" "$f" "$w" "$r" "$l" "$c"
	done
}

head -c 1024 /dev/urandom > "$TMP/sens-small.bin"

echo "directory entries, 32Mi partition, 512Ki payload"
for n in 16 64 128; do measure "entries=$n" 32Mi 524288 "$n"; done
echo
echo "payload size, 32Mi partition, 16 entries"
for p in 131072 524288 2097152; do measure "payload=$p" 32Mi "$p" 16; done
echo
echo "partition size, 512Ki payload, 16 entries"
for s in 16Mi 32Mi 128Mi; do measure "size=$s" "$s" 524288 16; done

rm -f "$TMP"/sens*.hdf "$TMP"/sens-back.bin "$TMP"/sens-pl.bin "$TMP"/sens-small.bin
