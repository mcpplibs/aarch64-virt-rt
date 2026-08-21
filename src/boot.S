// The entry point for QEMU's aarch64 `virt` machine.
//
// ⚠️ A ZERO-LIBC BOARD HAS TO SUPPLY THIS ITSELF, AND THAT IS THE ONE PLACE
// THIS PACKAGE DOES MORE THAN `riscv-virt-rt`.
//
// On the picolibc path a crt0 comes from the C library and the board only
// SELECTS one (`crt0-semihost` vs a UART crt0 — a board choice, per that
// package's own note). With no C library there is no crt0 to select, so the
// board writes the twenty instructions itself. That is a difference in what the
// package CONTAINS, not in the directives it emits — see the note in build.mcpp.

    .section .text.boot, "ax"
    .global _start
_start:
    // qemu starts every core; the secondaries would race through the same boot
    // path and clear .bss underneath core 0. Park them.
    mrs     x0, mpidr_el1
    and     x0, x0, #0xff
    cbz     x0, 1f
0:  wfe
    b       0b

1:  // The stack pointer is undefined at reset. The linker script places
    // __stack_top above the image.
    adrp    x0, __stack_top
    add     x0, x0, :lo12:__stack_top
    mov     sp, x0

    // ⚠️ .bss IS NOT ZEROED BY ANYTHING ELSE. `-kernel` loads the PT_LOAD
    // segments; .bss occupies no file space and arrives holding whatever the
    // machine left there. A C++ program with a zero-initialised static reads
    // garbage without this loop, and the failure is data-dependent — which is
    // to say it will not reproduce on the machine where it was written.
    adrp    x0, __bss_start
    add     x0, x0, :lo12:__bss_start
    adrp    x1, __bss_end
    add     x1, x1, :lo12:__bss_end
2:  cmp     x0, x1
    b.hs    3f
    str     xzr, [x0], #8
    b       2b

3:  bl      main
    // main returned. There is no operating system to return TO, so ask qemu to
    // power the machine off through PSCI; if that is unavailable, park.
    mov     x0, #0x84000000
    movk    x0, #0x0008           // PSCI SYSTEM_OFF (0x84000008)
    hvc     #0
4:  wfe
    b       4b
