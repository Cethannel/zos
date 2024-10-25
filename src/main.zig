const Kernel = @import("kernel/kernel.zig");
const tty = @import("kernel/tty.zig");
const std = @import("std");

const MultiBoot = @import("kernel/multiboot.zig");

const assert = @import("std").debug.assert;

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = stack_trace;
    _ = ret_addr;
    tty.printf("{s}", .{message});
    while (true) {}
}

export fn kmain(magic: u32, bootInfo: *MultiBoot.MultibootInfo) noreturn {
    @setRuntimeSafety(false);
    assert(magic == MultiBoot.MULTIBOOT_BOOTLOADER_MAGIC);
    Kernel.kernelMain(bootInfo);
    while (true) {}
}
