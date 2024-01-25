const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/interrupts.zig");
const Timer = @import("arch/i386/timer.zig");
const Keyboard = @import("arch/i386/keyboard.zig");
const Memory = @import("arch/i386/memory.zig");
const MultiBoot = @import("multiboot.zig");

const TTYi = @import("arch/i386/tty.zig");

export const interthing: u8 = 0;

pub fn kernelMain(boot_info: *MultiBoot.multiboot_info) void {
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    IDT.new_init();
    Timer.init();
    Keyboard.init();

    const mod1 = boot_info.mods_addr + 4;
    var fff: u32 = 0xFFF;
    const physicalAllocStart = (mod1 + 0xFFF) & ~fff;

    //TTYi.write_test();

    Memory.init(boot_info.mem_upper * 1024, physicalAllocStart);

    kstd.printf("Hello, kernel world!\n", .{});

    while (true) {
        asm volatile ("hlt");
    }
}
