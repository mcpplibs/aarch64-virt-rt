# aarch64-virt-rt

Board support for QEMU's aarch64 `virt` machine, on the **zero-libc tier**.

```
xlings install qemu-arm -y      # once
mcpp run --target aarch64-none-elf
```

```cpp
import mcpplibs.aarch64_virt_rt;

extern "C" int main() {
    board::println("hello from qemu aarch64 virt");
    return 0;
}
```

Nothing in that program names a load address, a UART address, a linker script,
`-nostdlib` or an emulator. That is what a board package is for.

## ⭐ Why this package exists, and what it was written to find out

`riscv-virt-rt` was the ecosystem's only board package, and a board-package
*model* validated by exactly one board cannot be distinguished from a model that
happens to fit that board. This is the same trap `openarch` fell into with two
RISC machines: an interface that fits both may fit because it is right, or
because they are alike.

`riscv-virt-rt` holds three things fixed — the ISA, the presence of a C library,
and the emulator board. A second board on the same ISA would vary only the
third, which is the weakest of the three available. So this one varies two:

* a **different ISA**, and
* the **zero-libc tier**, which asks a question nobody had asked: are *board
  package* and *C library provider* two separable roles?

## The finding

⭐ **They are separable, and the board-package interface is complete.**

Measured from the two build programs' own cache records — which are the engine's
record of what each emitted, not a reading of their source:

```
riscv-virt-rt      ldflag runner
aarch64-virt-rt    ldflag runner
```

**The same two directives.** The C library shows up as different *values*, not
as a directive one board needs and the other cannot express:

```
riscv-virt-rt      -lcrt0-semihost  -lc  -lsemihost
                   -lclang_rt.builtins-riscv64  -T …/picolibcpp.ld
aarch64-virt-rt    -T …/virt.ld
```

⚠️ **The test could have failed and that would have been the more valuable
result.** Had this board needed something `riscv-virt-rt` cannot express, the
board-package interface would have been incomplete — which is worth more than a
second board is.

## The one real difference, and it is content rather than interface

With no C library there is no `crt0` to select, so this package **ships** an
entry point (`src/boot.S`) where `riscv-virt-rt` picks between picolibc's. Its
twenty instructions park the secondary cores, set the stack, and zero `.bss`.

⚠️ **`.bss` is not zeroed by anything else.** `-kernel` loads the PT_LOAD
segments; `.bss` occupies no file space and arrives holding whatever the machine
left there. A zero-initialised static reads garbage without that loop, and the
failure is data-dependent — it will not reproduce on the machine where the code
was written. `examples/blinky` asserts it rather than assuming it.

## What it does not do

| | |
|---|---|
| A C library | This is the zero-libc tier. `xim:picolibc-aarch64` exists and a project that wants it declares it — that is the project's choice, and taking it here would make the board the thing that decided |
| A heap, `printf` | Same reason: those come from a C library |
| Real hardware | The board is the emulator. A board package whose claims can only be checked on the author's desk has no reproducible criterion |

## The memory map

⚠️ **0x40000000 is not a preference.** qemu's aarch64 `virt` places RAM there,
and `-kernel` loads an ELF at the addresses the ELF names. An image linked at
riscv `virt`'s 0x80000000 lands outside the default 128 MB and the machine sits
doing nothing — measured while building `picolibc-aarch64`, where the same image
ran once qemu was given 4 GB. **A load address that only works on a generously
configured machine is the worst kind of wrong: it passes.**
