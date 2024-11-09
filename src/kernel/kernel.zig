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
const kmalloc = @import("arch/i386/kmalloc.zig");
const speeker = @import("arch/i386/speeker.zig");
const serial = @import("arch/i386/serial.zig");
const std = @import("std");

const TTYi = @import("arch/i386/tty.zig");

export var interthing: u8 = 0;

extern const thing: [*]u16;

pub fn kernelMain(boot_info: *const MultiBoot.MultibootInfo) void {
    serial.init() catch unreachable;
    TTY.terminal_initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    kstd.printf("Intializing IDT\n", .{});

    Timer.init();
    IDT.init();

    kstd.printf("Initializing Keyboard\n", .{});
    Keyboard.init();

    const mod1: u32 = @as(*u32, @ptrFromInt(boot_info.mods_addr + 4)).*;
    const physcalAllocStart: u32 = (mod1 + 0xFFF) & ~@as(u32, 0xFFF);
    _ = &physcalAllocStart;

    speeker.beep();

    //_ = physcalAllocStart;
    _ = Memory;

    const table = Memory.getPageTable();

    kstd.print("Entries: \n", .{});
    for (table.entries) |entry| {
        if (@as(u32, @bitCast(entry)) != 0) {
            kstd.print("Got thing: {any}\n", .{entry});
            serial.print("Got thing: {any}\n", .{entry});
        }
    }

    while (true) {}
}
