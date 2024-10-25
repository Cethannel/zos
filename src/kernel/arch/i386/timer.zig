const InterruptRegisters = @import("util.zig").InterruptRegisters;
const Interrups = @import("interrupts.zig");
const kstd = @import("../../kernel_std.zig");

const outb = @import("util.zig").outb;

var ticks: u64 = 0;
const FREQUENCY: u64 = 100;

pub fn init() void {
    ticks = 0;

    const divisor: u32 = 1193180 / FREQUENCY;

    //0011 0110
    outb(0x43, 0x36);
    outb(0x40, (divisor & 0xFF));
    outb(0x40, ((divisor >> 8) & 0xFF));

    Interrups.registerIRQ(0, onIrq0);

    kstd.print("Timer initialized\n", .{});
}

pub fn getTicks() u64 {
    return ticks;
}

fn onIrq0() void {
    ticks += 1;
}
