/* The memory map of QEMU's aarch64 `virt` machine.
 *
 * Where this machine begins executing, and where its RAM is, are the two facts
 * a program cannot derive and cannot guess. They are also the two facts that do
 * not change between one program on this board and the next — which makes them
 * exactly what a board package is for.
 *
 * ⚠️ 0x40000000 IS NOT A PREFERENCE. qemu's aarch64 `virt` places RAM there,
 * and `-kernel` loads an ELF at the addresses the ELF names. An image linked at
 * riscv `virt`'s 0x80000000 lands outside the default 128 MB and the machine
 * sits doing nothing — measured while building `picolibc-aarch64`, where the
 * same image ran once qemu was given 4 GB. A load address that only works on a
 * generously configured machine is the worst kind of wrong: it passes.
 */
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x40000000, LENGTH = 128M
}

SECTIONS {
    . = 0x40000000;

    .text : { KEEP(*(.text.boot)) *(.text .text.*) } > RAM
    .rodata : ALIGN(8) { *(.rodata .rodata.*) } > RAM
    .data   : ALIGN(8) { *(.data .data.*) }     > RAM

    .bss : ALIGN(16) {
        __bss_start = .;
        *(.bss .bss.* COMMON)
        . = ALIGN(16);
        __bss_end = .;
    } > RAM

    /* The stack grows down from the top of the image, not from the top of RAM:
     * a board package cannot know how much RAM the user will give qemu, and
     * `-m` is a runtime argument. 64 KiB is enough for a boot path and is what
     * the entry code below assumes. */
    . = ALIGN(16);
    . += 0x10000;
    __stack_top = .;

    /DISCARD/ : { *(.comment) *(.note.*) *(.eh_frame) }
}
