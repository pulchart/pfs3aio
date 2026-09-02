# pfs3aio

Fork of [tonioni/pfs3aio](https://github.com/tonioni/pfs3aio), the PFS3 filesystem handler for AmigaOS.

It exists to build the handler from source per target CPU, from several toolchains. Along the way it shows what the compiler and the target CPU are actually worth.

- [TOOLCHAINS.md](TOOLCHAINS.md): how the builds are produced, what each toolchain does to the code, and what the 68060 constrains.
- [BENCHMARK.md](BENCHMARK.md): what filesystem operations cost in CPU cycles per toolchain, build and emulated CPU.

## Building

```sh
make              # every toolchain, one binary per target CPU, into compare/
make install      # side by side as pfs3aio.<toolchain> under /opt/AmigaOS/pfs/v20.0
make verify       # format, write, read back, plus the 68060 instruction audit
make -f makefile  # upstream's own single-binary build, untouched
```

**Branches:** `master` mirrors upstream, development happens on `jpu`.
