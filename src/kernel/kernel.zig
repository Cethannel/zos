const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/interrupts.zig");
const Timer = @import("arch/i386/timer.zig");
const Keyboard = @import("arch/i386/keyboard.zig");
const Memory = @import("arch/i386/memory.zig");
const MultiBoot = @import("multiboot.zig");

export const interthing: u8 = 0;

pub fn kernelMain(boot_info: *MultiBoot.multiboot_info) void {
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    IDT.new_init();
    Timer.init();
    Keyboard.init();

    Memory.init(boot_info);

    kstd.printf("Hello, kernel world!\n", .{});

    while (true) {
        asm volatile ("hlt");
    }
}
