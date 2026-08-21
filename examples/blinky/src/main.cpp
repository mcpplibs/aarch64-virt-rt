import mcpplibs.aarch64_virt_rt;

// ⚠️ Nothing here names a load address, a UART address, a linker script,
// `-nostdlib` or an emulator. That is what the board package is for.
//
// It also names no C library, and there is none: this is the zero-libc tier.
// `main` is reached from the package's own entry point, and a `static` below
// proves .bss was zeroed — which nothing does unless the board's boot code does.
static unsigned long long counter;

extern "C" int main() {
    board::println("hello from qemu aarch64 virt");

    // .bss must have been cleared by the board's entry code. A garbage value
    // here is data-dependent and would not reproduce on the machine where the
    // code was written, so it is asserted rather than assumed.
    board::print("bss ");
    board::println(counter == 0 ? "zeroed" : "DIRTY");
    if (counter != 0) return 1;

    counter = 42;
    board::print("counter ");
    board::print_uint(counter);
    board::putc('\n');

    board::println("blinky ok");
    return 0;
}
