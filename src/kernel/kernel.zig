const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/interrupts.zig");

export const interthing: u8 = 0;

pub fn kernelMain() void {
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    IDT.new_init();

    kstd.printf("Hello, kernel world!\n", .{});

    while (true) {}
}
