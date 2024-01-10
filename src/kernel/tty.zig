const TTY = @import("arch/i386/tty.zig");

pub fn terminal_initialize() void {
    TTY.initialize();
}

pub fn terminal_putchar(c: u8) void {
    TTY.putchar(c);
}

pub fn terminal_write(data: []const u8, size: usize) void {
    TTY.write(data, size);
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    TTY.printf(format, args);
}
