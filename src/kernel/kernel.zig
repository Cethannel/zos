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
const std = @import("std");

const TTYi = @import("arch/i386/tty.zig");

export var interthing: u8 = 0;

extern const thing: [*]u16;

pub fn kernelMain(boot_info: *const MultiBoot.MultibootInfo) void {
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

    speeker.beep();

    //_ = physcalAllocStart;
    _ = Memory;

    kstd.printf("Eceptions messages: 0x{X}\n", .{@intFromPtr(IDT.exception_messages[0].ptr)});
    kstd.printf("thing: 0x{X}\n", .{@intFromPtr(thing)});

    Memory.init(boot_info.mem_upper * 1024, physcalAllocStart);

    TTY.reinit();

    //kstd.printf("Initialized memory\n", .{});
    TTY.TTY.putc('N');
    TTY.TTY.printExample();

    kstd.simpleFn(1);
    TTY.TTY.printExample();

    //std.builtin.CallingConvention.

    //if (1 == 1) {
    //    @panic("YAY");
    //}

    kmalloc.init(0x1000);

    kstd.simpleFn(1);

    TTY.TTY.printExample();

    kstd.printf("Hello\n\x00", .{});

    while (true) {}
}
