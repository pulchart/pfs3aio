# pfs3aio

Fork of [tonioni/pfs3aio](https://github.com/tonioni/pfs3aio), the PFS3 filesystem handler for AmigaOS.

It exists to build the handler from source per target CPU, from several toolchains. Along the way it shows what the compiler and the target CPU are actually worth.

- [TOOLCHAINS.md](TOOLCHAINS.md): how the builds are produced, what each toolchain does to the code, and what the 68060 constrains.
- [BENCHMARK.md](BENCHMARK.md): what filesystem operations cost in CPU cycles per toolchain, build and emulated CPU.

## Binaries

Every binary names its own build in the `$VER` string, readable with `Version <file> FULL`. [BENCHMARK.md](BENCHMARK.md) compares them.

**These are not official builds and they are untested. Use them at your own risk.** They exist so the differences between the compilers and the target CPUs can be tried on real hardware. How a build behaves on your machine, and anything you notice about the builds themselves, is welcome in [issues here](https://github.com/pulchart/pfs3aio/issues), and a fix is best sent as a pull request. A bug in PFS3 itself belongs [upstream](https://github.com/tonioni/pfs3aio/issues), once it reproduces with an official build and is not down to the compiler.

Builds are attached to the [releases](https://github.com/pulchart/pfs3aio/releases), each with a table of every build. Files are named `pfs3aio-<tag>-<tier>-<toolchain>`.

## Building

```sh
make              # every toolchain, one binary per target CPU, into compare/
make install      # side by side as pfs3aio.<toolchain> under /opt/AmigaOS/pfs/v20.0
make dist         # the release set into dist/, which git ignores
make verify       # format, write, read back, plus the instruction audits
make -f makefile  # upstream's own single-binary build, untouched
```

**Branches:** `master` mirrors upstream, development happens on `jpu`.
