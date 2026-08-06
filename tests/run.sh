#!/bin/zsh
# pfs3aio behaviour + fix-validation tests under AmiFUSE.
#
#   zsh run.sh [--driver PATH] [--stock PATH] [--image PATH]... [--quick]
#
# Defaults: driver = ../pfs3aio (built from this repo), images = every *.hdf
# in tests/fixtures/. Run tests/make-supermode.sh first to create the
# supermode fixture. Each test runs on a throwaway (sparse-preserving) copy.
set -u
SCRIPT_DIR=${0:A:h}
REPO=${SCRIPT_DIR:h}
FI=$SCRIPT_DIR/fi.py
TMP=$SCRIPT_DIR/.tmp
FIXDIR=$SCRIPT_DIR/fixtures
DRV=$REPO/pfs3aio
STOCK=""
QUICK=0
typeset -a IMAGES
IMAGES=()

while [ $# -gt 0 ]; do
  case $1 in
    --driver) DRV=$2; shift 2;;
    --stock)  STOCK=$2; shift 2;;
    --image)  IMAGES+=$2; shift 2;;
    --quick)  QUICK=1; shift;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done
[ ${#IMAGES} -eq 0 ] && IMAGES=($FIXDIR/*.hdf(N))
[ ${#IMAGES} -eq 0 ] && { echo "no images (pass --image, or run make-supermode.sh)"; exit 2; }
command -v amifuse >/dev/null || { echo "amifuse not on PATH"; exit 2; }
[ -x $DRV ] || { echo "driver not found/executable: $DRV"; exit 2; }

mkdir -p $TMP
pass=0; fail=0
ok(){ print -r -- "    PASS  $1"; pass=$((pass+1)); return 0; }
no(){ print -r -- "    FAIL  $1"; fail=$((fail+1)); return 0; }
# sparse-preserving copy (APFS clonefile), falling back to plain cp
cpy(){ /bin/cp -c "$1" "$2" 2>/dev/null || /bin/cp "$1" "$2"; }
# file count reported by `verify`, or empty string if the volume won't mount
count(){ FI_CMD=none python3 $FI verify "$1" --driver $DRV 2>/dev/null \
           | /usr/bin/grep -oE "Files: [0-9]+" | /usr/bin/grep -oE "[0-9]+"; }
# is N one of the acceptable post-op counts in the list of remaining args?
isin(){ local n=$1; shift; for x in "$@"; do [ "$n" = "$x" ] && return 0; done; return 1; }

mk(){ dd if=/dev/urandom of=$1 bs=$2 count=$3 2>/dev/null; }
mk $TMP/odd.bin   1    777      # sub-block -> read-modify-write tail
mk $TMP/multi.bin 1024 600      # 600 KB multi-block
# ~120 MB: at the emulator's ~75 MB/s the write phase lasts ~1.6 s, long
# enough for the T5 kill delays below to land mid-write (not after commit).
mk $TMP/big.bin   1048576 120

for IMG in $IMAGES; do
  base=$(count $IMG)
  print -r -- "== image: ${IMG:t}  (driver ${DRV:t}, baseline ${base:-UNMOUNTABLE} files)"
  [ -z "$base" ] && { no "image does not mount"; continue; }
  n1=$((base+1))

  # T1  functional round-trip; odd-size + multi-block, byte-exact
  cpy $IMG $TMP/t1.hdf
  FI_CMD=none python3 $FI write $TMP/t1.hdf --file ODD   --in $TMP/odd.bin   --driver $DRV >/dev/null 2>&1
  FI_CMD=none python3 $FI write $TMP/t1.hdf --file MULTI --in $TMP/multi.bin --driver $DRV >/dev/null 2>&1
  FI_CMD=none python3 $FI read  $TMP/t1.hdf --file ODD   --out $TMP/o1 --driver $DRV >/dev/null 2>&1
  FI_CMD=none python3 $FI read  $TMP/t1.hdf --file MULTI --out $TMP/o2 --driver $DRV >/dev/null 2>&1
  { cmp -s $TMP/o1 $TMP/odd.bin && cmp -s $TMP/o2 $TMP/multi.bin } \
     && ok "T1 write/read round-trip (odd + multiblock) byte-exact" || no "T1 round-trip"
  if [ -n "$STOCK" ]; then
    FI_CMD=none python3 $FI read $TMP/t1.hdf --file MULTI --out $TMP/o2s --driver $STOCK >/dev/null 2>&1
    cmp -s $TMP/o2s $TMP/multi.bin && ok "T1 data reads back on STOCK driver (on-disk format compatible)" \
                                    || no "T1 stock cross-read"
  fi

  # T2  format then round-trip (on a copy; reformats the partition)
  cpy $IMG $TMP/t2.hdf
  part=$(FI_CMD=none python3 $FI format $TMP/t2.hdf 0 TV --driver $DRV 2>&1 | /usr/bin/grep -qi "Format complete" && echo ok)
  if [ "$part" = ok ]; then
    FI_CMD=none python3 $FI write $TMP/t2.hdf --file X --in $TMP/multi.bin --driver $DRV >/dev/null 2>&1
    FI_CMD=none python3 $FI read  $TMP/t2.hdf --file X --out $TMP/o3 --driver $DRV >/dev/null 2>&1
    cmp -s $TMP/o3 $TMP/multi.bin && ok "T2 format + write + read round-trip" || no "T2 format round-trip"
  else
    no "T2 format did not complete"
  fi

  # T3  I/O-error resilience: inject read & write faults on many targets;
  #     never crash the emulator, always leave the volume consistent (base or base+1).
  t3=1
  for spec in "r 0 0 2 999999999" "r 0 0 8 40" "w 0 0 5000 999999999" "w 0 0 2 800" \
              "r 1 0 5000 999999999" "w 1 1 0 999999999" "w 3 1 0 999999999"; do
    set -- ${=spec}
    cpy $IMG $TMP/t3.hdf
    FI_CMD=$1 FI_COUNT=$2 FI_REQ=$3 FI_LO=$4 FI_HI=$5 \
      python3 $FI write $TMP/t3.hdf --file R --in $TMP/odd.bin --driver $DRV >/dev/null 2>$TMP/t3.err
    /usr/bin/grep -q FI-EXCEPTION $TMP/t3.err && { t3=0; print "      emulator crash on fault [$spec]"; }
    c=$(count $TMP/t3.hdf); isin "$c" $base $n1 || { t3=0; print "      volume inconsistent after [$spec]: files=${c:-DEAD}"; }
  done
  [ $t3 = 1 ] && ok "T3 no crash + volume consistent across read/write fault injection" \
              || no "T3 I/O-error resilience"

  # T4  crash-consistency: deterministic power cut just before the Nth write,
  #     swept across N. Every remount must be a clean base or base+1, never broken.
  t4=1; steps="1 3 5 7 9 11 13 16 20 26 34"
  [ $QUICK = 1 ] && steps="3 9 16 26"
  for n in ${=steps}; do
    cpy $IMG $TMP/t4.hdf
    FI_CMD=none FI_CRASHN=$n python3 $FI write $TMP/t4.hdf --file C --in $TMP/multi.bin --driver $DRV >/dev/null 2>&1
    c=$(count $TMP/t4.hdf); isin "$c" $base $n1 || { t4=0; print "      crash@write=$n left files=${c:-DEAD} (not a clean $base/$n1)"; }
  done
  [ $t4 = 1 ] && ok "T4 atomic commit holds at every deterministic power-cut point" \
              || no "T4 crash-consistency (deterministic)"

  # T5  external power loss: launch a ~120 MB write, kill -9 the amifuse
  #     process while it is still writing, remount and require consistency
  #     (base or base+1). FI_FLUSH makes prior writes persist, so the killed
  #     image is a faithful power cut. Per-kill outcome is printed so it is
  #     visible that the kill landed mid-write (a mix of rolled-back/committed).
  if [ $QUICK = 0 ]; then
    t5=1; full=$(wc -c < $TMP/big.bin)
    for d in 0.3 0.6 1.0; do
      cpy $IMG $TMP/t5.hdf
      FI_FLUSH=1 python3 $FI write $TMP/t5.hdf --file BIG --in $TMP/big.bin --driver $DRV >/dev/null 2>&1 &
      pid=$!
      sleep $d
      kill -9 $pid 2>/dev/null; wait $pid 2>/dev/null
      c=$(count $TMP/t5.hdf)
      isin "$c" $base $n1 || { t5=0; print "      kill@${d}s left files=${c:-DEAD} (not a clean $base/$n1)"; continue; }
      # the killed volume must still be readable; report how much of BIG persisted
      got=NA
      if isin "$c" $n1; then
        FI_CMD=none python3 $FI read $TMP/t5.hdf --file BIG --out $TMP/got --driver $DRV >/dev/null 2>&1
        got=$([ -f $TMP/got ] && wc -c < $TMP/got || echo UNREADABLE); rm -f $TMP/got
        [ "$got" = UNREADABLE ] && t5=0
      else got=0-rolledback; fi
      print "      kill@${d}s: volume OK, BIG persisted ${got}/${full} bytes"
    done
    [ $t5 = 1 ] && ok "T5 volume consistent after external kill -9 during a large write" \
                || no "T5 external-kill power loss"
  fi
done

print -r -- "== TOTAL: $pass passed, $fail failed =="
rm -rf $TMP
exit $([ $fail -eq 0 ] && echo 0 || echo 1)
