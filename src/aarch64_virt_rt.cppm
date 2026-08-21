// The board's upward face.
//
// A consumer imports this and names nothing else: no load address, no UART
// address, no `-nostdlib`, no linker script, no emulator. Those are exactly the
// facts a board package exists to own.
//
// ⚠️ THE SURFACE IS DELIBERATELY SMALLER THAN `riscv-virt-rt`'s, AND THE
// DIFFERENCE IS THE C LIBRARY RATHER THAN THE BOARD.
//
// That package exports `printf` and a heap because picolibc supplies them. This
// one is on the zero-libc tier, so it exports what a UART and a linker script
// can support and nothing more. A project that wants `printf` here declares
// `xim:picolibc-aarch64` — which is a project's decision, and making it here
// would be the board deciding on the project's behalf.

module;

export module mcpplibs.aarch64_virt_rt;

export namespace board {

// The PL011 UART qemu's `virt` places at 0x09000000.
//
// ⚠️ Written as a plain store rather than through a "wait for TXFF clear" loop:
// under qemu the FIFO never fills, and a readiness loop on a device that never
// reports busy is untestable code that reads like caution. Real hardware needs
// the loop; this board is the emulator, and the comment is the honest form of
// that difference.
inline void putc(char c) {
    *reinterpret_cast<volatile unsigned int*>(0x09000000) = static_cast<unsigned int>(c);
}

inline void print(const char* s)   { for (; s && *s; ++s) putc(*s); }
inline void println(const char* s) { print(s); putc('\n'); }

// Unsigned decimal, because a board with no C library still has to be able to
// show a number, and `print(int)` is the smallest thing that is not a formatter.
inline void print_uint(unsigned long long v) {
    char buf[21];
    int i = 20;
    buf[i] = '\0';
    if (v == 0) buf[--i] = '0';
    while (v) { buf[--i] = static_cast<char>('0' + (v % 10)); v /= 10; }
    print(&buf[i]);
}

// Stop the machine. `main` returning does this too; a program that finishes
// early says so itself.
[[noreturn]] inline void poweroff() {
    asm volatile("mov x0, #0x84000000\n\t"
                 "movk x0, #0x0008\n\t"
                 "hvc #0" ::: "x0", "memory");
    for (;;) asm volatile("wfe");
}

}  // namespace board
