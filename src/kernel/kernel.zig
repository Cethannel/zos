const std = @import("std");
const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const builtin = @import("builtin");

const arch = switch (builtin.cpu.arch) {
    .x86 => @import("arch/i386/init.zig"),
    .x86_64 => @import("arch/amd64/init.zig"),
    else => unreachable,
};

pub const MultiBoot = arch.MultiBoot;

export var interthing: u8 = 0;

extern const thing: [*]u16;

pub fn kernelMain(boot_info: *const MultiBoot.MultibootInfo) void {
    arch.init(boot_info) catch unreachable;

    //_ = physcalAllocStart;

    while (true) {}
}
