#!/bin/zsh
# Top-level entry point: the live-source proofs (no driver/emulator needed) and,
# if a built driver + amifuse are available, the black-box AmiFUSE suite.
#
#   zsh tests/run-all.sh [--driver PATH] [--stock PATH] [--quick]
set -u
DIR=${0:A:h}
DRV=""
typeset -a STOCK QUICK
STOCK=(); QUICK=()
while [ $# -gt 0 ]; do
  case $1 in
    --driver) DRV=$2; shift 2;;
    --stock)  STOCK=(--stock $2); shift 2;;
    --quick)  QUICK=(--quick); shift;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done
rc=0

echo "===== live-source proofs (fail on broken tree, pass on fixed) ====="
zsh $DIR/live/run.sh || rc=1

# black-box layer is optional: needs amifuse + a built driver
[ -z "$DRV" ] && [ -x ${DIR:h}/pfs3aio ] && DRV=${DIR:h}/pfs3aio
if command -v amifuse >/dev/null && [ -n "$DRV" ] && [ -x $DRV ]; then
  echo "\n===== black-box AmiFUSE suite ====="
  [ -f $DIR/fixtures/super.hdf ] || zsh $DIR/make-supermode.sh --driver $DRV
  zsh $DIR/run.sh --driver $DRV $STOCK $QUICK || rc=1
else
  echo "\n(skipping black-box suite: needs amifuse on PATH and --driver PATH to a built driver)"
fi

echo "\n===== overall: $([ $rc = 0 ] && echo GREEN || echo FAILURES) ====="
exit $rc
