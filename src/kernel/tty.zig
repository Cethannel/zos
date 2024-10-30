pub const TTY = @import("arch/i386/tty.zig");

pub fn terminal_initialize() void {
    TTY.initialize();
}

pub fn reinit() void {
    TTY.reinit();
}

pub fn terminal_putchar(c: u8) void {
    TTY.putchar(c);
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}
