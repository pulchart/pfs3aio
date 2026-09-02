#!/usr/bin/env python3
"""Emulator patches shared by the two benchmarks, and a vamos front end.

As a module it offers the two fixes tests/m68k/bench.sh and
tests/m68k/driverbench.py both need. As a script it is vamos with those fixes
applied:

    python3 tests/m68k/vamos_cpu.py -q -C 68030 <binary> [args]
    CYCLES=1 python3 tests/m68k/vamos_cpu.py -q -C 68000 <binary> [args]

With CYCLES set to anything but 0, no, false or off it writes "CYCLES <n>" and
the guest exit code as "RC <n>" to stderr.
"""

import os
import sys

from amitools.vamos.lib.ExecLibrary import ExecLibrary
from amitools.vamos.machine.machine import Machine

# AFF_68010 | AFF_68020 | AFF_68030 | AFF_68040, no FPU bits: vamos has no FPU.
FLAGS = {"68010": 0x01, "68020": 0x03, "68030": 0x07, "68030(fake)": 0x07,
         "68040": 0x0f}

# Cycles have to be accumulated in chunks. A caller can ask the emulator to run
# guest code in one call with a large budget, and that call need not return
# normally: under amifuse it unwinds with UnsupportedFeatureError when the
# handler reaches WaitPkt. The result object carrying the cycle count is then
# never produced and everything the guest did up to that point is lost.
# Chunking bounds the loss to one chunk and preserves what the caller sees,
# since a chunk that runs out of budget is simply continued. vamos's own run
# loop chunks at 1000, and the chunk has to stay that small: a run that ends in
# WaitPkt loses its last chunk, and with a large chunk that loss dominates the
# measurement. At 100000 the same PFS3 write came out as 72681 cycles for one
# build and 886009 for another while both issued exactly 87 block writes.
CHUNK = int(os.environ.get("BENCH_CHUNK", "1000"))


def enabled(name):
    """Truth of an environment switch, with 0 meaning off.

    os.environ.get() on its own would not do: every non-empty string is truthy
    in Python, so CYCLES=0 would turn counting on.
    """
    return os.environ.get(name, "").strip().lower() \
        not in ("", "0", "no", "false", "off")

stats = {"calls": 0, "cycles": 0}


def patch_attn_flags():
    """Make -C 68030 usable.

    vamos derives exec.library's AttnFlags from the CPU name but compares
    against "68030(fake)", a name machine68k no longer reports, so a 68030 run
    leaves AttnFlags at 0. Startup code of a 68020+ binary checks that field
    and aborts with alert 00068020. vamos also sets 127 for 68040, which claims
    a 68060 that is not there.
    """
    _setup_lib = ExecLibrary.setup_lib

    def setup_lib(self, ctx, base_addr):
        _setup_lib(self, ctx, base_addr)
        self.exec_lib.attn_flags.val = FLAGS.get(ctx.cpu_name, 0)

    ExecLibrary.setup_lib = setup_lib


def count_cycles():
    """Sum the cycles Musashi charges for every instruction it interprets.

    Unlike host wall clock, which tracks how many instructions the interpreter
    got through, this is CPU-model dependent: it is what makes a 68000 figure
    differ from a 68020 one for the same binary. It still counts nothing
    outside the CPU core, so no memory wait states, no caches, no chip-RAM
    contention.
    """
    _execute = Machine.execute

    def execute(self, max_cycles=1000):
        stats["calls"] += 1
        left = max_cycles
        er = None
        while left > 0:
            n = CHUNK if left > CHUNK else left
            er = _execute(self, n)
            stats["cycles"] += er.cycles
            left -= n
            if self.was_exit(er) or er.cycles == 0:
                break
        return er

    Machine.execute = execute


if __name__ == "__main__":
    from amitools.tools.vamos import main

    patch_attn_flags()
    counting = enabled("CYCLES")
    if counting:
        count_cycles()
    rc = 2
    try:
        rc = main()
    finally:
        if counting:
            sys.stderr.write("CYCLES %d\nRC %s\n" % (stats["cycles"], rc))
    sys.exit(rc)
