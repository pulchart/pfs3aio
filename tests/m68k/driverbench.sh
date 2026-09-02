#!/bin/sh
# Runs real driver operations through each built binary, on each emulated CPU
# and at both PFS3 block sizes, and reports the cycles Musashi charged.
#
#   sh tests/m68k/driverbench.sh [compare-dir]
#   CPUS="68000 68020 68030 68040" sh tests/m68k/driverbench.sh
#   BLOCKSIZES=4096 DIRENTRIES=128 sh tests/m68k/driverbench.sh
#
# Operations, one column each:
#   fmt     format a fresh image
#   wr      write a $PAYLOAD byte file
#   rd      read that file back
#   ls      list a directory holding $DIRENTRIES entries
#   create  write one more file into that directory
#
# fmt and wr run against a fresh image, which is the thing being measured. rd,
# ls and create run against a copy of a template image populated once per block
# size, so every build starts from the identical on-disk state. The on-disk
# format does not depend on the compiler, so the template can be built by any
# of them.
#
# 68030 and 68040 are not in the default CPU list. Musashi keeps a separate cost
# table per CPU type, but 507 of its 514 opcode specs and all 13
# effective-address modes carry the same figure for 68020, 68030 and 68040, so
# those columns come out identical to 68020 by construction. Add them to CPUS to
# see it.
#
# Same limits as tests/m68k/bench.sh: only instructions the emulated CPU
# interprets are counted, exec/dos/scsi.device are host-side traps and cost
# nothing, and nothing outside the CPU core is modelled.

set -u
DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$DIR/../.." && pwd)
OUT=${1:-$ROOT/compare}
TMP=$ROOT/tests/.tmp
SIZE=${SIZE:-32Mi}
PAYLOAD=${PAYLOAD:-524288}
DIRENTRIES=${DIRENTRIES:-64}
. "$ROOT/tests/m68k/tiers.sh"
# Default list plus every tier minimum, or a tier would have no column it can
# run in and would measure nothing.
CPUS=${CPUS:-$(tier_cpus 68000 68020)}
# PFS3 logical block size, set on the RDB partition with rdbtool's bs=. Not the
# same thing as amifuse's --block-size, which is the sector size of the device.
BLOCKSIZES=${BLOCKSIZES:-"512 4096"}

command -v rdbtool >/dev/null 2>&1 || { echo "ERROR: rdbtool not on PATH"; exit 2; }
python3 -c "import amifuse" 2>/dev/null || { echo "ERROR: amifuse not importable"; exit 2; }

mkdir -p "$TMP"
head -c "$PAYLOAD" /dev/urandom > "$TMP/payload.bin"
head -c 1024 /dev/urandom > "$TMP/small.bin"

DRIVERS=$(ls "$OUT"/*/*/pfs3aio 2>/dev/null)
[ -n "$DRIVERS" ] || { echo "ERROR: no drivers under $OUT"; exit 2; }

# The template is built once per block size and reused by every build, so its
# driver only has to produce the right bytes on disk, not to be the build under
# test. It must be one that runs at TEMPLATE_CPU: picking the first driver
# alphabetically breaks as soon as that is a tier the template CPU cannot run.
TEMPLATE_CPU=${TEMPLATE_CPU:-68020}
if [ -z "${REF:-}" ]; then
	for d in $DRIVERS; do
		t=${d%/pfs3aio}; t=${t##*/}
		if tier_runs_on "$t" "$TEMPLATE_CPU"; then REF=$d; break; fi
	done
fi
[ -n "${REF:-}" ] || { echo "ERROR: no driver under $OUT runs on $TEMPLATE_CPU"; exit 2; }

newimg() {	# $1=path $2=blocksize
	rm -f "$1"
	rdbtool -f "$1" create size=$SIZE + init + add name=DH0 size=95% \
		dostype=0x50465303 bs=$2 >/dev/null 2>&1
}

run() {	# $1=cpu, rest=amifuse args -> kilocycles, or "fail"
	cpu=$1; shift
	out=$(BENCH_CPU=$cpu python3 "$DIR"/driverbench.py "$@" 2>&1 >/dev/null)
	n=$(printf '%s' "$out" | sed -n 's/.*DRIVERBENCH .*cycles=\([0-9]*\).*/\1/p')
	rc=$(printf '%s' "$out" | sed -n 's/.*DRIVERBENCH .*rc=\([0-9]*\).*/\1/p')
	if [ "$rc" != 0 ] || [ -z "$n" ]; then echo fail; return 1; fi
	echo $((n / 1000))
}

template() {	# $1=blocksize -> populates $TMP/template-$1.hdf
	t=$TMP/template-$1.hdf
	[ -f "$t" ] && return 0
	echo "populating a $1 byte block template, $DIRENTRIES entries" >&2
	newimg "$t" "$1"
	run "$TEMPLATE_CPU" format "$t" DH0 V --driver "$REF" >/dev/null || return 1
	run "$TEMPLATE_CPU" write "$t" --file F --in "$TMP/payload.bin" --driver "$REF" >/dev/null \
		|| return 1
	i=0
	while [ "$i" -lt "$DIRENTRIES" ]; do
		i=$((i + 1))
		run "$TEMPLATE_CPU" write "$t" --file "F$i" --in "$TMP/small.bin" --driver "$REF" \
			>/dev/null || return 1
	done
}

fail=0
for bs in $BLOCKSIZES; do
	template "$bs" || { echo "ERROR: template failed at bs=$bs"; exit 2; }
	for cpu in $CPUS; do
		echo
		echo "$bs byte PFS3 blocks, $cpu, kilocycles ($PAYLOAD byte payload, $DIRENTRIES dir entries)"
		echo
		printf "%-14s %7s %7s %7s %7s %7s  %s\n" \
			build fmt wr rd ls create readback
		for drv in $DRIVERS; do
			name=$(echo "$drv" | sed "s|^$OUT/||; s|/pfs3aio$||")
			tier=${name#*/}
			# a tier only runs on its minimum CPU and up, see tiers.mk
			if ! tier_runs_on "$tier" "$cpu"; then
				printf "%-14s %7s %7s %7s %7s %7s  %s\n" \
					"$name" - - - - - -
				continue
			fi
			img=$TMP/driverbench.hdf
			newimg "$img" "$bs"
			f=$(run "$cpu" format "$img" DH0 V --driver "$drv")
			if [ "$f" = fail ]; then
				printf "%-14s %7s\n" "$name" fail
				fail=$((fail + 1))
				continue
			fi
			w=$(run "$cpu" write "$img" --file F --in "$TMP/payload.bin" \
				--driver "$drv")
			[ "$w" = fail ] && fail=$((fail + 1))

			# rd, ls and create from the shared template, so the
			# directory holds the same entries for every build
			cp "$TMP/template-$bs.hdf" "$img"
			rm -f "$TMP/back.bin"
			r=$(run "$cpu" read "$img" --file F --out "$TMP/back.bin" \
				--driver "$drv")
			if cmp -s "$TMP/payload.bin" "$TMP/back.bin"; then
				back=ok
			else
				back=BAD
				fail=$((fail + 1))
			fi
			l=$(run "$cpu" ls "$img" --driver "$drv")
			[ "$l" = fail ] && fail=$((fail + 1))
			c=$(run "$cpu" write "$img" --file NEXT --in "$TMP/small.bin" \
				--driver "$drv")
			[ "$c" = fail ] && fail=$((fail + 1))

			printf "%-14s %7s %7s %7s %7s %7s  %s\n" \
				"$name" "$f" "$w" "$r" "$l" "$c" "$back"
		done
	done
done

rm -f "$TMP/driverbench.hdf" "$TMP/back.bin" "$TMP/payload.bin" "$TMP/small.bin" \
	"$TMP"/template-*.hdf
echo
echo "== driverbench: $fail failed =="
[ "$fail" -eq 0 ]
