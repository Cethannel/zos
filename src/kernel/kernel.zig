const kstd = @import("kernel_std.zig");
const TTY = @import("tty.zig");
const GDT = @import("arch/i386/gdt.zig");
const IDT = @import("arch/i386/idt.zig");
const Timer = @import("arch/i386/timer.zig");
const Keyboard = @import("arch/i386/keyboard.zig");
const Memory = @import("arch/i386/memory.zig");
const MultiBoot = @import("multiboot.zig");

const TTYi = @import("arch/i386/tty.zig");

export const interthing: u8 = 0;

pub fn kernelMain(boot_info: *MultiBoot.multiboot_info) void {
    _ = boot_info;
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    kstd.printf("Intializing IDT\n", .{});

    IDT.init();

    asm volatile (
        \\ .loop:
        \\ jmp .loop
    );

    kstd.printf("Initializeing Timer\n", .{});
    Timer.init();

    kstd.printf("Initializeing Keyboard\n", .{});
    Keyboard.init();

    kstd.printf("Initializeing Memory\n", .{});
    //const mod1 = boot_info.mods_addr + 4;
    //const fff: u32 = 0xFFF;
    //const physicalAllocStart = (mod1 + 0xFFF) & ~fff;

    //Memory.init(boot_info.mem_upper * 1024, physicalAllocStart);

    kstd.printf("Hello, kernel World!\n", .{});

    const tick = Timer.getTicks();

    while (Timer.getTicks() < tick + 100) {
        asm volatile ("hlt");
    }

    TTYi.terminal_write("Hello, kernel World!\n");

    while (true) {
        asm volatile ("hlt");
    }
}
