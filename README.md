# pfs3aio

Fork of [tonioni/pfs3aio](https://github.com/tonioni/pfs3aio), the PFS3 filesystem handler for AmigaOS.

It exists to build the handler from source per target CPU, from several toolchains. Along the way it shows what the compiler and the target CPU are actually worth.

- [TOOLCHAINS.md](TOOLCHAINS.md): how the builds are produced, what each toolchain does to the code, and what the 68060 constrains.
- [BENCHMARK.md](BENCHMARK.md): what filesystem operations cost in CPU cycles per toolchain, build and emulated CPU.

## Binaries

Every binary names its own build in the `$VER` string, readable with `Version <file> FULL`. [BENCHMARK.md](BENCHMARK.md) compares them.

**These are not official builds and they are untested. Use them at your own risk.** They exist so the differences between the compilers and the target CPUs can be tried on real hardware. How a build behaves on your machine, and anything you notice about the builds themselves, is welcome in [issues here](https://github.com/pulchart/pfs3aio/issues), and a fix is best sent as a pull request. A bug in PFS3 itself belongs [upstream](https://github.com/tonioni/pfs3aio/issues), once it reproduces with an official build and is not down to the compiler.

<!-- dist-table -->
## GCC 13.4

| build | runs on | tag | size | download |
|---|---|---|---|---|
| `68000` | 68000 to 68060 | `[gcc13.4/000][000+][jpu/20260902-1]` | 65852 | [pfs3aio.gcc13][gcc13-68000] |
| `68020` | 68020 to 68060 | `[gcc13.4/020][020+][jpu/20260902-1]` | 63876 | [pfs3aio.gcc13][gcc13-68020] |
| `68030` | 68020 to 68040 | `[gcc13.4/030][020-040][jpu/20260902-1]` | 63820 | [pfs3aio.gcc13][gcc13-68030] |
| `68040` | 68020 to 68040 | `[gcc13.4/040][020-040][jpu/20260902-1]` | 64024 | [pfs3aio.gcc13][gcc13-68040] |
| `68060` | 68020 to 68060 | `[gcc13.4/060][020+][jpu/20260902-1]` | 63876 | [pfs3aio.gcc13][gcc13-68060] |

## GCC 6.5

| build | runs on | tag | size | download |
|---|---|---|---|---|
| `68000` | 68000 to 68060 | `[gcc6.5/000][000+][jpu/20260902-1]` | 66148 | [pfs3aio.gcc6][gcc6-68000] |
| `68030` | 68020 to 68040 | `[gcc6.5/030][020-040][jpu/20260902-1]` | 64776 | [pfs3aio.gcc6][gcc6-68030] |
| `68040` | 68020 to 68040 | `[gcc6.5/040][020-040][jpu/20260902-1]` | 65188 | [pfs3aio.gcc6][gcc6-68040] |
| `68060` | 68020 to 68060 | `[gcc6.5/060][020+][jpu/20260902-1]` | 64816 | [pfs3aio.gcc6][gcc6-68060] |
| `68080` | 68080 only | `[gcc6.5/080][080][jpu/20260902-1]` | 63744 | [pfs3aio.gcc6][gcc6-68080] |

## GCC 15.2

| build | runs on | tag | size | download |
|---|---|---|---|---|
| `68000` | 68000 to 68060 | `[gcc15.2/000][000+][jpu/20260902-1]` | 66472 | [pfs3aio.gcc15][gcc15-68000] |
| `68020` | 68020 to 68060 | `[gcc15.2/020][020+][jpu/20260902-1]` | 64296 | [pfs3aio.gcc15][gcc15-68020] |
| `68030` | 68020 to 68040 | `[gcc15.2/030][020-040][jpu/20260902-1]` | 64332 | [pfs3aio.gcc15][gcc15-68030] |
| `68040` | 68020 to 68040 | `[gcc15.2/040][020-040][jpu/20260902-1]` | 64448 | [pfs3aio.gcc15][gcc15-68040] |
| `68060` | 68020 to 68060 | `[gcc15.2/060][020+][jpu/20260902-1]` | 64296 | [pfs3aio.gcc15][gcc15-68060] |

## GCC 16.1

| build | runs on | tag | size | download |
|---|---|---|---|---|
| `68000` | 68000 to 68060 | `[gcc16.1/000][000+][jpu/20260902-1]` | 66820 | [pfs3aio.gcc16][gcc16-68000] |
| `68020` | 68020 to 68060 | `[gcc16.1/020][020+][jpu/20260902-1]` | 64528 | [pfs3aio.gcc16][gcc16-68020] |
| `68030` | 68020 to 68040 | `[gcc16.1/030][020-040][jpu/20260902-1]` | 64816 | [pfs3aio.gcc16][gcc16-68030] |
| `68040` | 68020 to 68040 | `[gcc16.1/040][020-040][jpu/20260902-1]` | 64868 | [pfs3aio.gcc16][gcc16-68040] |
| `68060` | 68020 to 68060 | `[gcc16.1/060][020+][jpu/20260902-1]` | 64528 | [pfs3aio.gcc16][gcc16-68060] |

## vbcc

| build | runs on | tag | size | download |
|---|---|---|---|---|
| `68000` | 68000 to 68060 | `[vbcc/000][000+][jpu/20260902-1]` | 85576 | [pfs3aio.vbcc][vbcc-68000] |
| `68020` | 68020 to 68060 | `[vbcc/020][020+][jpu/20260902-1]` | 79632 | [pfs3aio.vbcc][vbcc-68020] |

[gcc13-68000]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68000/pfs3aio.gcc13
[gcc13-68020]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68020/pfs3aio.gcc13
[gcc13-68030]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68030/pfs3aio.gcc13
[gcc13-68040]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68040/pfs3aio.gcc13
[gcc13-68060]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68060/pfs3aio.gcc13
[gcc6-68000]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68000/pfs3aio.gcc6
[gcc6-68030]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68030/pfs3aio.gcc6
[gcc6-68040]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68040/pfs3aio.gcc6
[gcc6-68060]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68060/pfs3aio.gcc6
[gcc6-68080]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68080/pfs3aio.gcc6
[gcc15-68000]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68000/pfs3aio.gcc15
[gcc15-68020]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68020/pfs3aio.gcc15
[gcc15-68030]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68030/pfs3aio.gcc15
[gcc15-68040]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68040/pfs3aio.gcc15
[gcc15-68060]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68060/pfs3aio.gcc15
[gcc16-68000]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68000/pfs3aio.gcc16
[gcc16-68020]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68020/pfs3aio.gcc16
[gcc16-68030]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68030/pfs3aio.gcc16
[gcc16-68040]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68040/pfs3aio.gcc16
[gcc16-68060]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68060/pfs3aio.gcc16
[vbcc-68000]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68000/pfs3aio.vbcc
[vbcc-68020]: https://raw.githubusercontent.com/pulchart/pfs3aio/20260902-1/dist/68020/pfs3aio.vbcc
<!-- /dist-table -->

## Building

```sh
make              # every toolchain, one binary per target CPU, into compare/
make install      # side by side as pfs3aio.<toolchain> under /opt/AmigaOS/pfs/v20.0
make verify       # format, write, read back, plus the 68060 instruction audit
make -f makefile  # upstream's own single-binary build, untouched
```

**Branches:** `master` mirrors upstream, development happens on `jpu`.
