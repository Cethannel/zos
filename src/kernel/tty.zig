const builtin = @import("builtin");

pub const TTY = switch (builtin.cpu.arch) {
    .x86 => @import("arch/i386/tty.zig"),
    .x86_64 => @import("arch/amd64/tty.zig"),
    else => @import("tty is not supported on this architecture"),
};

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
