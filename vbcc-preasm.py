#!/usr/bin/env python3
"""Translate this tree's GNU-as assembly into what vasm's std syntax accepts.

  cpp -Ivbcc-inc -P startup.s | python3 vbcc-preasm.py > startup_vbcc.s

startup.s is written for GNU as but mixes in Motorola pseudo-ops, and vasm
accepts neither dialect wholesale. Two rewrites are needed:

  dc.b/dc.w/dc.l   ->  .byte/.word/.long
  numeric local labels ("1:" with "1f"/"1b" references) -> unique names

The label numbers are reused across blocks, so each "N:" gets its own name and
every reference is resolved to the nearest matching one in the right direction.
"""
import re, sys

src = sys.stdin.read().splitlines()

src = [re.sub(r'\bdc\.b\b', '.byte',
       re.sub(r'\bdc\.w\b', '.word',
       re.sub(r'\bdc\.l\b', '.long', l))) for l in src]

# every "N:" definition, in order
defs = [(i, m.group(1)) for i, l in enumerate(src)
        for m in [re.match(r'^\s*(\d+):', l)] if m]

def name(idx, num):
    return ".Lloc_%s_%d" % (num, idx)

out = []
for i, line in enumerate(src):
    m = re.match(r'^(\s*)(\d+):(.*)$', line)
    if m:
        out.append("%s%s:%s" % (m.group(1), name(i, m.group(2)), m.group(3)))
        continue

    def ref(mo):
        num, direction = mo.group(1), mo.group(2)
        cands = [d for d in defs if d[1] == num]
        if direction == 'f':
            later = [d for d in cands if d[0] > i]
            if not later:
                sys.exit("vbcc-preasm: no forward label %s%s at line %d" % (num, direction, i + 1))
            return name(later[0][0], num)
        earlier = [d for d in cands if d[0] < i]
        if not earlier:
            sys.exit("vbcc-preasm: no backward label %s%s at line %d" % (num, direction, i + 1))
        return name(earlier[-1][0], num)

    out.append(re.sub(r'\b(\d+)([fb])\b', ref, line))

print("\n".join(out))
