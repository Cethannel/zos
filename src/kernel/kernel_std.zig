const TTY = @import("tty.zig");
const builtin = @import("builtin");

pub const util = switch (builtin.cpu.arch) {
    .x86 => @import("arch/i386/util.zig"),
    .x86_64 => @import("arch/amd64/util.zig"),
    else => @import("util is not supported on this architecture"),
};

pub fn printf(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}

pub fn print(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}

pub fn kerror(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}

pub fn kpanic(comptime format: []const u8, args: anytype) noreturn {
    TTY.printf(format, args);
    util.panic("kpanic");
}

pub noinline fn simpleFn(a: u32) void {
    _ = a;
    asm volatile ("nop");
}
