const Kernel = @import("kernel/kernel.zig");

const MultiBoot = @import("kernel/multiboot.zig");

const assert = @import("std").debug.assert;

export fn kmain(magic: u32, bootInfo: *MultiBoot.MultibootInfo) noreturn {
    assert(magic == MultiBoot.MULTIBOOT_BOOTLOADER_MAGIC);
    Kernel.kernelMain(bootInfo);
    while (true) {}
}
