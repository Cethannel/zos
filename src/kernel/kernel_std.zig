const TTY = @import("tty.zig");
const util = @import("arch/i386/util.zig");

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
