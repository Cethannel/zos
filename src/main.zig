const Kernel = @import("kernel/kernel.zig");
const tty = @import("kernel/tty.zig");
const std = @import("std");

const assert = @import("std").debug.assert;

const MultiBoot = Kernel.MultiBoot;

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = &message;
    _ = &ret_addr;
    _ = &stack_trace;
    asm volatile ("sti");
    tty.TTY.puts("\nPANIC: \x00");
    tty.TTY.terminal_write(message);
    tty.TTY.puts("\n\x00");
    //if (stack_trace) |st| {
    //    tty.printf("\nStack trance: {}\n", .{st});
    //}
    while (true) {}
}

export fn kmain(magic: u32, bootInfo: *MultiBoot.MultibootInfo) noreturn {
    @setRuntimeSafety(false);
    assert(magic == MultiBoot.MULTIBOOT_BOOTLOADER_MAGIC);
    Kernel.kernelMain(bootInfo);
    while (true) {}
}
