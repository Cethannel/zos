const InterruptRegisters = @import("util.zig").InterruptRegisters;
const Interrups = @import("interrupts.zig");
const kstd = @import("../../kernel_std.zig");

const outb = @import("util.zig").outb;

var ticks: u64 = 0;
const FREQUENCY: u64 = 100;

pub fn init() void {
    ticks = 0;
    Interrups.irq_install_handler(0, onIrq0);

    const divisor: u32 = 1193180 / FREQUENCY;

    //0011 0110
    outb(0x43, 0x36);
    outb(0x40, (divisor & 0xFF));
    outb(0x40, ((divisor >> 8) & 0xFF));

    //kstd.print("Timer initialized\n", .{});
}

fn onIrq0(regs: *InterruptRegisters) void {
    _ = regs;
    ticks += 1;
}
