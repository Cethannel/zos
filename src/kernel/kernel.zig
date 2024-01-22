const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/interrupts.zig");
const Timer = @import("arch/i386/timer.zig");
const Keyboard = @import("arch/i386/keyboard.zig");

export const interthing: u8 = 0;

pub fn kernelMain() void {
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    IDT.new_init();
    Timer.init();
    Keyboard.init();

    kstd.printf("Hello, kernel world!\n", .{});
    for (0..1024 * 1024) |i| {
        _ = i;
        kstd.printf("H", .{});
    }

    while (true) {}
}
