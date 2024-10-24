const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/idt.zig");
const Timer = @import("arch/i386/timer.zig");
const Keyboard = @import("arch/i386/keyboard.zig");
const Memory = @import("arch/i386/memory.zig");
const pmem = @import("arch/i386/pmem.zig");
const MultiBoot = @import("multiboot.zig");
const x86 = @import("arch/i386/x86.zig");

const TTYi = @import("arch/i386/tty.zig");

export const interthing: u8 = 0;

pub fn kernelMain(boot_info: *const MultiBoot.MultibootInfo) void {
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    kstd.printf("Intializing IDT\n", .{});

    IDT.init();

    //kstd.printf("Initializeing Timer\n", .{});
    //Timer.init();

    kstd.printf("Initializing Keyboard\n", .{});
    Keyboard.init();

    _ = boot_info;

    asm volatile (
        \\ kmloop:
        \\  hlt
        \\  jmp kmloop
    );
}
