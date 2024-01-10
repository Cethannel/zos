const TTY = @import("tty.zig").TTY;

pub fn printf(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}

pub fn kerror(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}
