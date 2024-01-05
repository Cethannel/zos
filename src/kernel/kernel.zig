const TTY = @import("tty.zig");

pub fn kernel_main() void {
    TTY.terminal_initialize();

    TTY.printf("Hello, kernel world!\n", .{});

    for (0..25) |i| {
        TTY.printf("Hello, kernel world! {}\n", .{i});
    }
}
