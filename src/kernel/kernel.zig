const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");

pub fn kernel_main() void {
    TTY.terminal_initialize();
    GDT.init();

    kstd.printf("Hello, kernel world!\n", .{});

    for (0..25) |i| {
        kstd.printf("Hello, kernel world! {}\n", .{i});
    }
}
