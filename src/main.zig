const Kernel = @import("kernel/kernel.zig");

export fn kmain() noreturn {
    Kernel.kernelMain();
    while (true) {}
}
