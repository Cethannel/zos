const Kernel = @import("kernel/kernel.zig");

export fn kmain() noreturn {
    Kernel.kernel_main();
    while (true) {}
}
