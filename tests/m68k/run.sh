#!/bin/sh
# Builds the m68k-side tests and runs them under vamos.
#
#   sh tests/m68k/run.sh
#
# Needs amitools with a working machine68k. Point VAMOS at the binary if it is
# not on PATH; amitools 0.8.0 with machine68k 0.4.1 does not work together
# (Traps.set_exc_func is gone), 0.8.1 pins 0.3.0 and does.
#
# Each test lifts the real function out of the driver source the way
# tests/live does, so it cannot drift from what ships.

set -u
DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$DIR/../.." && pwd)
VAMOS=${VAMOS:-vamos}
GCC=${GCC:-$HOME/opt/m68k-amigaos/bin/m68k-amigaos-gcc}
CPU=${CPU:-68000}

# Musashi, the CPU core behind vamos, emulates up to 68040: no 68060. So the
# 68020 codegen can be checked here, but not the 68060's missing instructions.
# Those are covered statically instead, see TOOLCHAINS.md "Target CPU: 68060".
case "$CPU" in
68000|68010|68020|68030|68040) VCPU=$CPU ;;
*) echo "NOTE: $CPU is not emulated by Musashi, running the binary on 68020"; VCPU=68020 ;;
esac

command -v "$VAMOS" >/dev/null 2>&1 || { echo "ERROR: no vamos ($VAMOS)"; exit 1; }
[ -x "$GCC" ] || { echo "ERROR: no compiler ($GCC)"; exit 1; }

mkdir -p "$DIR/gen"
pass=0
fail=0

extract() {	# $1=file $2=func
	awk -v fn="$2" '
		!ins && $0 ~ ("^[a-zA-Z].*" fn "[[:space:]]*[(]") && $0 !~ /;/ { ins=1 }
		ins { print; o=gsub(/{/,"{"); c=gsub(/}/,"}"); n+=o-c; if(n>0) seen=1; if(seen && n==0) exit }
	' "$1"
}

for t in "$DIR"/*_m68k.c; do
	[ -e "$t" ] || continue
	name=$(basename "$t" .c)
	src=$(grep -oE '@src [^ ]+' "$t" | awk '{print $2}' | head -1)
	fn=$(grep -oE '@func [A-Za-z_][A-Za-z0-9_]*' "$t" | awk '{print $2}' | head -1)
	[ -n "$src" ] || src=vbcc_compat.c
	[ -n "$fn" ] || fn=$(echo "$name" | sed 's/_m68k$//')

	extract "$ROOT/$src" "$fn" > "$DIR/gen/$fn.c"
	if [ ! -s "$DIR/gen/$fn.c" ]; then
		echo "  MISS  $name: could not extract $fn from $src"
		fail=$((fail + 1))
		continue
	fi

	if ! "$GCC" -Os -noixemul -m$CPU -I"$DIR" -o "$DIR/$name" "$t" 2>"$DIR/gen/$name.log"; then
		echo "  BUILD $name (see gen/$name.log)"
		fail=$((fail + 1))
		continue
	fi

	echo "== $name (built m$CPU, emulated $VCPU)"
	if (cd "$DIR" && "$VAMOS" -q -C "$VCPU" "./$name"); then
		pass=$((pass + 1))
	else
		fail=$((fail + 1))
	fi
done

echo "== m68k: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
