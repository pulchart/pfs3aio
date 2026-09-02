# PFS3 handler: emulated-cycle comparison of m68k toolchains

Not a bug report and not a request for anything: just an observation I thought was worth sharing.

I have been building pfs3aio from source for a while now, and at some point I started wondering what actually determines what a filesystem operation costs: how much of it is the CPU model, how much the compiler version, and how much the CPU the build is aimed at.

So I ran a set of driver operations under vamos and counted the cycles the emulator charges for the instructions it executes. It is an estimate and nothing more: no waiting on the system is measured, and nothing outside the CPU core is modelled.

The operations, on a 32 MiB image:

- `fmt` format it fresh
- `wr` write a 512 KiB file
- `rd` read that file back
- `ls` list a directory holding 64 entries
- `create` write one more file into that directory

`rd`, `ls` and `create` run against a copy of one template image per block size, so every build starts from the identical on-disk state.

What follows are the tables that came out of my measurements.

Toolchains: gcc 6.5.0b, 13.4.0b, 15.2.0 and 16.1.1b, all from `docker.io/stefanreinauer/amiga-gcc`, plus vbcc 0.9.

The tables below use the `68000` build and the highest one each toolchain has, which is `68060` for the gcc versions and `68020` for vbcc. The rest are compared separately under "Which build for which machine".

## Format and write

Kilocycles. The two right-aligned columns are not measurements: they are speed relative to row 3, the baseline for all three tables. Lower is slower, so 0.50x means the operation takes twice the cycles.

| # | compiler | CPU | build | 512 fmt | 512 wr | 4K fmt | 4K wr | wr speed 512 | wr speed 4K |
|---|---|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 68000 | 580 | 1950 | 633 | 1490 | _0.48x_ | _0.44x_ |
| 2 | gcc 6.5 | 68020 | 68000 | 270 | 1137 | 305 | 710 | _0.82x_ | _0.93x_ |
| 3 | gcc 6.5 (baseline) | 68020 | 68060 | 268 | 928 | 298 | 661 | _1.00x_ | _1.00x_ |
| 4 | gcc 13.4 | 68000 | 68000 | 611 | 2457 | 668 | 1579 | _0.38x_ | _0.42x_ |
| 5 | gcc 13.4 | 68020 | 68000 | 292 | 1165 | 321 | 739 | _0.80x_ | _0.89x_ |
| 6 | gcc 13.4 | 68020 | 68060 | 282 | 1000 | 311 | 692 | _0.93x_ | _0.96x_ |
| 7 | gcc 15.2 | 68000 | 68000 | 601 | 1976 | 644 | 1567 | _0.47x_ | _0.42x_ |
| 8 | gcc 15.2 | 68020 | 68000 | 290 | 1144 | 314 | 738 | _0.81x_ | _0.90x_ |
| 9 | gcc 15.2 | 68020 | 68060 | 279 | 968 | 303 | 674 | _0.96x_ | _0.98x_ |
| 10 | gcc 16.1 | 68000 | 68000 | 652 | 1984 | 674 | 1599 | _0.47x_ | _0.41x_ |
| 11 | gcc 16.1 | 68020 | 68000 | 311 | 1157 | 327 | 756 | _0.80x_ | _0.87x_ |
| 12 | gcc 16.1 | 68020 | 68060 | 284 | 953 | 305 | 661 | _0.97x_ | _1.00x_ |
| 13 | vbcc | 68000 | 68000 | 829 | 2769 | 1193 | 2434 | _0.34x_ | _0.27x_ |
| 14 | vbcc | 68020 | 68000 | 375 | 1327 | 520 | 1144 | _0.70x_ | _0.58x_ |
| 15 | vbcc | 68020 | 68020 | 356 | 1192 | 500 | 1045 | _0.78x_ | _0.63x_ |

## Read and list

Kilocycles, same builds and same rows, against the same baseline. Row 3 is the cheapest listing but not the cheapest read: at 4096 byte blocks the `68000` build of gcc 6.5 reads faster, 215 against 224.

| # | compiler | CPU | build | 512 rd | 512 ls | 4K rd | 4K ls | ls speed 512 | ls speed 4K |
|---|---|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 68000 | 394 | 735 | 460 | 813 | _0.38x_ | _0.41x_ |
| 2 | gcc 6.5 | 68020 | 68000 | 182 | 353 | 215 | 392 | _0.80x_ | _0.85x_ |
| 3 | gcc 6.5 (baseline) | 68020 | 68060 | 181 | 282 | 224 | 332 | _1.00x_ | _1.00x_ |
| 4 | gcc 13.4 | 68000 | 68000 | 413 | 751 | 534 | 884 | _0.38x_ | _0.38x_ |
| 5 | gcc 13.4 | 68020 | 68000 | 190 | 358 | 243 | 418 | _0.79x_ | _0.79x_ |
| 6 | gcc 13.4 | 68020 | 68060 | 214 | 292 | 255 | 341 | _0.97x_ | _0.97x_ |
| 7 | gcc 15.2 | 68000 | 68000 | 412 | 749 | 547 | 895 | _0.38x_ | _0.37x_ |
| 8 | gcc 15.2 | 68020 | 68000 | 190 | 357 | 250 | 425 | _0.79x_ | _0.78x_ |
| 9 | gcc 15.2 | 68020 | 68060 | 201 | 290 | 245 | 342 | _0.97x_ | _0.97x_ |
| 10 | gcc 16.1 | 68000 | 68000 | 430 | 757 | 564 | 902 | _0.37x_ | _0.37x_ |
| 11 | gcc 16.1 | 68020 | 68000 | 204 | 360 | 264 | 427 | _0.78x_ | _0.78x_ |
| 12 | gcc 16.1 | 68020 | 68060 | 185 | 289 | 229 | 341 | _0.98x_ | _0.97x_ |
| 13 | vbcc | 68000 | 68000 | 581 | 819 | 689 | 941 | _0.34x_ | _0.35x_ |
| 14 | vbcc | 68020 | 68000 | 292 | 396 | 337 | 449 | _0.71x_ | _0.74x_ |
| 15 | vbcc | 68020 | 68020 | 251 | 389 | 286 | 432 | _0.72x_ | _0.77x_ |

## Create a file

Kilocycles, writing one more file into the directory the previous table lists. Same rows, same baseline.

| # | compiler | CPU | build | 512 create | 4K create | create speed 512 | create speed 4K |
|---|---|---|---|---|---|---:|---:|
| 1 | gcc 6.5 | 68000 | 68000 | 518 | 723 | _0.47x_ | _0.49x_ |
| 2 | gcc 6.5 | 68020 | 68000 | 250 | 353 | _0.96x_ | _1.00x_ |
| 3 | gcc 6.5 (baseline) | 68020 | 68060 | 241 | 353 | _1.00x_ | _1.00x_ |
| 4 | gcc 13.4 | 68000 | 68000 | 535 | 805 | _0.45x_ | _0.44x_ |
| 5 | gcc 13.4 | 68020 | 68000 | 254 | 381 | _0.95x_ | _0.93x_ |
| 6 | gcc 13.4 | 68020 | 68060 | 250 | 360 | _0.96x_ | _0.98x_ |
| 7 | gcc 15.2 | 68000 | 68000 | 529 | 802 | _0.46x_ | _0.44x_ |
| 8 | gcc 15.2 | 68020 | 68000 | 253 | 384 | _0.95x_ | _0.92x_ |
| 9 | gcc 15.2 | 68020 | 68060 | 245 | 357 | _0.98x_ | _0.99x_ |
| 10 | gcc 16.1 | 68000 | 68000 | 541 | 813 | _0.45x_ | _0.43x_ |
| 11 | gcc 16.1 | 68020 | 68000 | 259 | 389 | _0.93x_ | _0.91x_ |
| 12 | gcc 16.1 | 68020 | 68060 | 241 | 354 | _1.00x_ | _1.00x_ |
| 13 | vbcc | 68000 | 68000 | 741 | 1192 | _0.33x_ | _0.30x_ |
| 14 | vbcc | 68020 | 68000 | 360 | 547 | _0.67x_ | _0.65x_ |
| 15 | vbcc | 68020 | 68020 | 332 | 507 | _0.73x_ | _0.70x_ |

## Which build for which machine

One build per target CPU, each named after the machine you would install it on. The tag in the `$VER` string says which one a binary is and where it runs, readable with `Version <file> FULL` or `strings`:

| build | flag | runs on | tag |
|---|---|---|---|
| `68000` | `-m68000` | 68000 to 68060 | `[<cc>/000][000+]` |
| `68020` | `-m68020-60` | 68020 to 68060 | `[<cc>/020][020+]` |
| `68030` | `-m68030` | 68020 to 68040 | `[<cc>/030][020-040]` |
| `68040` | `-m68020-40` | 68020 to 68040 | `[<cc>/040][020-040]` |
| `68060` | `-m68060` | 68020 to 68060 | `[<cc>/060][020+]` |
| `68080` | `-m68080` | 68080 only | `[<cc>/080][080]` |

`<cc>` is `gcc6.5`, `gcc13.4`, `gcc15.2`, `gcc16.1` or `vbcc`. The first field is what the build is tuned for, the second where it runs. `68030` and `68040` stop at the 68040 because `-m68030` and `-m68020-40` emit eleven 64-bit `MULU.L` for divide-by-constant, which the 68060 does not implement.

gcc 6.5 has no `68020` build: its `-m68020-60` emits those multiplies too, where gcc 13.4 and later do not, so the build would not run on the 68060 the name promises.

The `68080` build is gcc 6.5 only and carries no figures here: it uses Apollo instructions that no emulator implements, so it can only be measured on hardware. See TOOLCHAINS.md, "Apollo 68080".

gcc 16.1 on an emulated 68020, kilocycles. 512 byte PFS3 blocks:

| build | flag | fmt | wr | rd | ls | create |
|---|---|---|---|---|---|---|
| `68000` | `-m68000` | 311 | 1157 | 204 | 360 | 259 |
| `68020` | `-m68020-60` | 283 | 945 | 184 | 287 | 239 |
| `68030` | `-m68030` | 279 | 963 | 195 | 291 | 241 |
| `68040` | `-m68020-40` | 275 | 941 | 182 | 286 | 236 |
| `68060` | `-m68060` | 284 | 953 | 185 | 289 | 241 |

4096 byte PFS3 blocks:

| build | flag | fmt | wr | rd | ls | create |
|---|---|---|---|---|---|---|
| `68000` | `-m68000` | 327 | 756 | 264 | 427 | 389 |
| `68020` | `-m68020-60` | 304 | 656 | 229 | 339 | 353 |
| `68030` | `-m68030` | 303 | 670 | 241 | 342 | 354 |
| `68040` | `-m68020-40` | 301 | 653 | 228 | 339 | 349 |
| `68060` | `-m68060` | 305 | 661 | 229 | 341 | 354 |

The emulator charges a 68020, a 68030 and a 68040 alike for every instruction these builds contain, so the table compares instruction selection and not the pipelines the builds are named for. An emulated 68040 gives the same 50 numbers, checked. There is no 68060 core at all.

## 4096 against 512 byte PFS3 blocks

Set on the RDB partition, `rdbtool ... add name=DH0 bs=4096`. Not amifuse's `--block-size`, which is the sector size of the device.

Larger blocks help exactly one operation. Same build, same payload:

| operation | change |
|---|---|
| write | 29-31% cheaper, 12% for vbcc |
| read | 14-24% more expensive |
| list a directory | 11-18% more expensive |
| create a file | 44-53% more expensive |
| format | 7-11% more expensive, 40% for vbcc |

The write is where fewer, larger blocks pay: the 512 KiB payload occupies 128 blocks instead of 1024, so anode lookups, bitmap updates and cache slot churn happen an eighth as often. Everything else is metadata work whose unit is a block, and the block got eight times bigger. Creating a file is worst, because it reads, modifies and writes back a full directory block.

It does not follow I/O count, which moves the other way for the write: 97 device requests at 4K against 87 at 512 bytes, and 17 format writes against 23. What changes is work per byte.

vbcc taking four times the format penalty fits where its weakness is, the replacement memory routines in `vbcc_compat.c`: format initialises 69632 bytes of metadata at 4K instead of 11776.

## Binary sizes

Bytes. vbcc builds only `68000` and `68020`.

| toolchain | 68000 | 68020 | 68030 | 68040 | 68060 |
|---|---|---|---|---|---|
| gcc 6.5 | 66132 | - | 64760 | 65172 | 64800 |
| gcc 13.4 | 65836 | 63856 | 63804 | 64008 | 63856 |
| gcc 15.2 | 66456 | 64280 | 64316 | 64432 | 64280 |
| gcc 16.1 | 66800 | 64512 | 64800 | 64852 | 64512 |
| vbcc | 85560 | 79616 | - | - | - |

## Observation

- **The 68060 build against the 68000 build, both on a 68020.** Helps the write, 10-18% at 512 byte blocks and 6-13% at 4K, and the directory listing, 18-20% for the gcc builds. Format and creating a file gain 1-9%. On reads it can be slower: gcc 13.4 loses 13% at 512 bytes to its own 68000 build, gcc 15.2 6%.
- **The CPU matters more than the build.** Moving the same 68000 build from a 68000 to a 68020 is 1.7-2.1x on the write. Switching that 68020 to the 68060 build then adds 1.22x at most.
