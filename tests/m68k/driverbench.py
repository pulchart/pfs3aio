#!/usr/bin/env python3
"""Runs one amifuse operation against a built driver at a chosen CPU and
reports the cycles Musashi charged for it.

amifuse hardwires the emulated CPU to 68020 and offers no option for it, so it
is patched here. The emulator fixes and the cycle counter come from
tests/m68k/vamos_cpu.py.

    BENCH_CPU=68000 python3 tests/m68k/driverbench.py write img.hdf \
        --file F --in payload.bin --driver compare/gcc6/68000/pfs3aio

Emits to stderr:
    DRIVERBENCH cpu=<cpu> calls=<n> cycles=<n> rc=<n>
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import amifuse.vamos_runner as vr  # noqa: E402
import vamos_cpu  # noqa: E402

CPU = os.environ.get("BENCH_CPU", "68020")

_setup = vr.VamosHandlerRuntime.setup


def setup(self, cpu=None):
    return _setup(self, cpu=CPU)


vr.VamosHandlerRuntime.setup = setup
vamos_cpu.patch_attn_flags()
vamos_cpu.count_cycles()

import amifuse.fuse_fs as ff  # noqa: E402  (after the patches above)

rc = 0
try:
    ff.main(sys.argv[1:])
except SystemExit as e:
    rc = e.code if isinstance(e.code, int) else (0 if e.code is None else 1)
except BaseException as e:
    sys.stderr.write("DRIVERBENCH-EXCEPTION: %s: %s\n" % (type(e).__name__, e))
    rc = 99

sys.stderr.write("DRIVERBENCH cpu=%s calls=%d cycles=%d rc=%s\n"
                 % (CPU, vamos_cpu.stats["calls"], vamos_cpu.stats["cycles"], rc))
sys.exit(rc if isinstance(rc, int) else 0)
