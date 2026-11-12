# PFS3 handler: emulated-cycle comparison of m68k toolchains

What decides the cost of a filesystem operation: the CPU model, the compiler, or the CPU the build is aimed at? I ran driver operations under vamos and counted the cycles the emulator charges for the instructions it executes. An estimate only: waiting on the system and anything outside the CPU core is not modelled.

The operations, on a 32 MiB image:

- `fmt` format it fresh
- `wr` write a 512 KiB file
- `rd` read that file back
- `ls` list a directory holding 64 entries
- `create` write one more file into that directory

`rd`, `ls` and `create` run against a copy of one template image per block size, so every build starts from the same on-disk state.

The handler arms a five second writeback deadline on `timer.device`. The emulator answers timer requests at once, which would expire it between two packets, so the harness holds the replies and never advances the clock. Figures taken with immediate replies are not comparable.

Toolchains: gcc 6.5.0b, 13.4.0b and 16.2.0b, all from `docker.io/stefanreinauer/amiga-gcc`.

The tables use the `000` build (68000+) and the `020` build (68020+) of each toolchain; gcc 6.5 has no `020` build. The rest are under "Which build for which machine".

## Format and write

Kilocycles. The two right-aligned columns are speed relative to row 8, gcc 16.2 with the `020` build on a 68020, the baseline for all three tables; 0.50x means twice the cycles.

| # | compiler | CPU | build | 512 fmt | 512 wr | 4K fmt | 4K wr | wr speed 512 | wr speed 4K |
|---|---|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 000 | 576 | 1190 | 625 | 779 | _0.46x_ | _0.49x_ |
| 2 | gcc 6.5 | 68020 | 000 | 272 | 529 | 304 | 371 | _1.03x_ | _1.02x_ |
| 3 | gcc 13.4 | 68000 | 000 | 611 | 1224 | 664 | 827 | _0.45x_ | _0.46x_ |
| 4 | gcc 13.4 | 68020 | 000 | 296 | 566 | 321 | 394 | _0.96x_ | _0.96x_ |
| 5 | gcc 13.4 | 68020 | 020 | 283 | 552 | 309 | 391 | _0.99x_ | _0.97x_ |
| 6 | gcc 16.2 | 68000 | 000 | 602 | 1214 | 641 | 812 | _0.45x_ | _0.47x_ |
| 7 | gcc 16.2 | 68020 | 000 | 294 | 560 | 316 | 386 | _0.97x_ | _0.98x_ |
| 8 | gcc 16.2 (baseline) | 68020 | 020 | 284 | 546 | 307 | 378 | _1.00x_ | _1.00x_ |

## Read and list

Kilocycles, same rows and baseline. Row 8 lists a directory and creates a file for the fewest cycles; row 2, gcc 6.5 with the `000` build, formats, writes and reads for fewer.

| # | compiler | CPU | build | 512 rd | 512 ls | 4K rd | 4K ls | ls speed 512 | ls speed 4K |
|---|---|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 000 | 370 | 647 | 428 | 711 | _0.47x_ | _0.48x_ |
| 2 | gcc 6.5 | 68020 | 000 | 171 | 308 | 203 | 343 | _0.98x_ | _0.99x_ |
| 3 | gcc 13.4 | 68000 | 000 | 397 | 686 | 470 | 765 | _0.44x_ | _0.45x_ |
| 4 | gcc 13.4 | 68020 | 000 | 187 | 320 | 227 | 363 | _0.95x_ | _0.94x_ |
| 5 | gcc 13.4 | 68020 | 020 | 199 | 308 | 237 | 349 | _0.98x_ | _0.98x_ |
| 6 | gcc 16.2 | 68000 | 000 | 399 | 675 | 473 | 749 | _0.45x_ | _0.46x_ |
| 7 | gcc 16.2 | 68020 | 000 | 187 | 318 | 221 | 356 | _0.95x_ | _0.96x_ |
| 8 | gcc 16.2 (baseline) | 68020 | 020 | 198 | 303 | 232 | 341 | _1.00x_ | _1.00x_ |

## Create a file

Kilocycles, one more file written into the directory the previous table lists. Same rows and baseline.

| # | compiler | CPU | build | 512 create | 4K create | create speed 512 | create speed 4K |
|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 000 | 406 | 585 | _0.48x_ | _0.49x_ |
| 2 | gcc 6.5 | 68020 | 000 | 197 | 290 | _0.98x_ | _0.99x_ |
| 3 | gcc 13.4 | 68000 | 000 | 423 | 626 | _0.46x_ | _0.46x_ |
| 4 | gcc 13.4 | 68020 | 000 | 202 | 306 | _0.96x_ | _0.94x_ |
| 5 | gcc 13.4 | 68020 | 020 | 194 | 293 | _1.00x_ | _0.98x_ |
| 6 | gcc 16.2 | 68000 | 000 | 416 | 604 | _0.47x_ | _0.48x_ |
| 7 | gcc 16.2 | 68020 | 000 | 199 | 294 | _0.97x_ | _0.98x_ |
| 8 | gcc 16.2 (baseline) | 68020 | 020 | 194 | 287 | _1.00x_ | _1.00x_ |

## Which build for which machine

One build per target CPU, named after the machine it is installed on. The `$VER` tag says which build a binary is and where it runs (`Version <file> FULL`):

| build | flag | runs on | tag |
|---|---|---|---|
| `000` | `-m68000` | 68000+ | `[<cc>/000][000+]` |
| `020` | `-m68020-60` | 68020+ | `[<cc>/020][020+]` |
| `030` | `-m68030` | 68020 to 68040 | `[<cc>/030][020-040]` |
| `040` | `-m68020-40` | 68020 to 68040 | `[<cc>/040][020-040]` |
| `060` | `-m68060` | 68020+ | `[<cc>/060][020+]` |
| `080` | `-m68060 -mtune=68080 -Wa,-m68080` | 68080 only | `[<cc>/080][080]` |
| `080a` | `-m68080` | 68080 only, line-A | `[<cc>/080a][080]` |

`<cc>` is `gcc6.5`, `gcc13.4` or `gcc16.2`. The first field is what the build is tuned for, the second where it runs. `030` and `040` stop at the 68040 because `-m68030` and `-m68020-40` emit 64-bit `MULU.L` for divide-by-constant, which the 68060 does not implement.

gcc 6.5 has no `020` build: its `-m68020-60` emits those multiplies too, so the build would not run on a 68060.

The `080` and `080a` builds are gcc 6.5 only and have no figures: they use Apollo instructions no emulator implements. See TOOLCHAINS.md, "Apollo 68080".

gcc 16.2 on an emulated 68020, kilocycles. 512 byte PFS3 blocks:

| build | flag | fmt | wr | rd | ls | create |
|---|---|---|---|---|---|---|
| `000` | `-m68000` | 294 | 560 | 187 | 318 | 199 |
| `020` | `-m68020-60` | 284 | 546 | 198 | 303 | 194 |
| `030` | `-m68030` | 283 | 538 | 187 | 306 | 190 |
| `040` | `-m68020-40` | 281 | 537 | 186 | 303 | 189 |
| `060` | `-m68060` | 286 | 547 | 199 | 306 | 195 |

4096 byte PFS3 blocks:

| build | flag | fmt | wr | rd | ls | create |
|---|---|---|---|---|---|---|
| `000` | `-m68000` | 316 | 386 | 221 | 356 | 294 |
| `020` | `-m68020-60` | 307 | 378 | 232 | 341 | 287 |
| `030` | `-m68030` | 305 | 371 | 221 | 343 | 284 |
| `040` | `-m68020-40` | 304 | 369 | 220 | 340 | 283 |
| `060` | `-m68060` | 308 | 379 | 233 | 344 | 288 |

The emulator charges a 68020, 68030 and 68040 alike for every instruction these builds contain, so the table compares instruction selection, not pipelines; an emulated 68040 gives the same numbers, checked. There is no 68060 core.

## 4096 against 512 byte PFS3 blocks

Set on the RDB partition, `rdbtool ... add name=DH0 bs=4096`, not amifuse's `--block-size`, which is the device sector size. Larger blocks help the write only. Same build, same payload:

| operation | change |
|---|---|
| write | cheaper |
| read | more expensive |
| list a directory | more expensive |
| create a file | more expensive, the most |
| format | more expensive |

The 512 KiB payload occupies 128 blocks instead of 1024, so anode lookups, bitmap updates and cache slot churn happen an eighth as often. Everything else is metadata work whose unit is a block, and the block got eight times bigger. Creating a file is worst: it reads, modifies and writes back a full directory block.

## Binary sizes

Bytes.

| toolchain | 000 | 020 | 030 | 040 | 060 |
|---|---|---|---|---|---|
| gcc 6.5 | 79060 | - | 77616 | 78092 | 77644 |
| gcc 13.4 | 77524 | 75148 | 75196 | 75412 | 75148 |
| gcc 16.2 | 78144 | 75996 | 76204 | 76392 | 75996 |

## Observation

- **The 020 build against the 000 build, both on a 68020.** Changes little: format, write, listing and file creation get 1 to 5 percent cheaper, the read 4 to 7 percent more expensive.
- **The CPU matters more than the build.** Moving the same 000 build from a 68000 to a 68020 roughly halves every operation. Switching that 68020 to the 020 build gains far less.
- **gcc 6.5 is the cheapest with the same build.** With the `000` build it needs the fewest cycles for every operation; gcc 13.4 and 16.2 need up to 8 percent more for the listing and up to 12 percent more for the read. gcc 16.2 with its `020` build lists a directory for less than gcc 6.5 with `000`.
