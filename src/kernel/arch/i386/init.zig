const TTY = @import("tty.zig");
const GDT = @import("gdt.zig");
const IDT = @import("idt.zig");
const Timer = @import("timer.zig");
const Keyboard = @import("keyboard.zig");
const Memory = @import("memory.zig");
const pmem = @import("pmem.zig");
pub const MultiBoot = @import("multiboot.zig");
const x86 = @import("x86.zig");
const kmalloc = @import("kmalloc.zig");
const speeker = @import("speeker.zig");
const serial = @import("serial.zig");
const pci = @import("pci.zig");
const kstd = @import("../../kernel_std.zig");

extern const kernel_virtual_start: usize;
extern const kernel_virtual_end: usize;
extern const kernel_physical_start: usize;
extern const kernel_physical_end: usize;

pub fn init(boot_info: *const MultiBoot.MultibootInfo) !void {
    asm volatile ("cli");
    serial.init() catch unreachable;
    TTY.initialize();

    kstd.printf("Intializing GDT\n", .{});

    GDT.init();

    kstd.printf("Intializing IDT\n", .{});

    Timer.init();

    serial.init_interrupt() catch unreachable;
    IDT.init();

    kstd.printf("Initializing Keyboard\n", .{});
    Keyboard.init();

    for (0..256) |bus| {
        for (0..256) |slot| {
            const dev = pci.CommandHeaders.get(@intCast(bus), @intCast(slot));
            if (dev.is_valid()) {
                serial.debug_print(dev);
            }
        }
    }

    const mod1: u32 = @as(*u32, @ptrFromInt(boot_info.mods_addr + 4)).*;
    const physcalAllocStart: u32 = (mod1 + 0xFFF) & ~@as(u32, 0xFFF);
    _ = &physcalAllocStart;

    speeker.beep();

    while (true) {}
}
