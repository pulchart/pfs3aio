# The tier table: everything that differs per build, and nowhere else.
#
# A build is named after the machine you install it on, which is what the
# directory means in dist/ and in INSTALL_DIR. Where else it runs is the
# MINCPU/MAXCPU pair below, not something the name carries.
#
# Read by makefile.gcc, makefile.vbcc and GNUmakefile, and from /bin/sh by
# tests/m68k/tiers.sh. Keep the "TIER_<FIELD>_<tier> = value" shape and every
# value one word: tests/m68k/tiers.sh parses this file with sed.
#
# Why each flag and each gap: TOOLCHAINS.md, "Target CPU: 68060".

TIERS = 68000 68020 68030 68040 68060 68080

# gcc -m flag.
TIER_CFLAGS_68000 = -m68000
TIER_CFLAGS_68020 = -m68020-60
TIER_CFLAGS_68030 = -m68030
TIER_CFLAGS_68040 = -m68020-40
TIER_CFLAGS_68060 = -m68060
TIER_CFLAGS_68080 = -m68080

# vbcc -cpu= value: the nearest plain CPU, since vbcc takes no combined ones.
# Every vbcc build is 68060 safe whatever this says.
TIER_VBCPU_68000 = 68000
TIER_VBCPU_68020 = 68020
TIER_VBCPU_68030 = 68030
TIER_VBCPU_68040 = 68040
TIER_VBCPU_68060 = 68060

# Toolchains that cannot build a given build, space separated.
#   gcc6: its -m68020-60 is not 68060 safe, unlike 13.4 and later
#   vbcc: generates the same code for 68020, 68030 and 68060
#   68080: only gcc 6.5 has -m68080; vbcc -cpu=68080 is its 68060 code
TIER_SKIP_68020 = gcc6
TIER_SKIP_68030 = vbcc
TIER_SKIP_68040 = vbcc
TIER_SKIP_68060 = vbcc
TIER_SKIP_68080 = gcc13 gcc15 gcc16 vbcc

# Lowest CPU the build runs on, so a harness knows which emulated CPU can run
# it.
TIER_MINCPU_68000 = 68000
TIER_MINCPU_68020 = 68020
TIER_MINCPU_68030 = 68020
TIER_MINCPU_68040 = 68020
TIER_MINCPU_68060 = 68020
TIER_MINCPU_68080 = 68080

# Highest CPU the build runs on. Only those reaching 68060 are scanned by
# tests/check68060.sh.
TIER_MAXCPU_68000 = 68060
TIER_MAXCPU_68020 = 68060
TIER_MAXCPU_68030 = 68040
TIER_MAXCPU_68040 = 68040
TIER_MAXCPU_68060 = 68060
TIER_MAXCPU_68080 = 68080

# Highest CPU Musashi implements, so the harnesses know which tiers they
# cannot run at all.
EMU_MAXCPU = 68040
