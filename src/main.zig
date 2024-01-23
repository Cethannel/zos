const Kernel = @import("kernel/kernel.zig");

const MultiBoot = @import("kernel/multiboot.zig");

export fn kmain(magic: u32, bootInfo: *MultiBoot.multiboot_info) noreturn {
    _ = magic;
    Kernel.kernelMain(bootInfo);
    while (true) {}
}
