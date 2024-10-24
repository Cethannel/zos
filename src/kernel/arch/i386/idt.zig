const gdt = @import("gdt.zig");
const interrupt = @import("interrupts.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const util = @import("util.zig");
const pic = @import("pic.zig");

pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE = 0xEE;

// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_low: u16 = 0,
    selector: u16 = 0,
    zero: u8 = 0,
    flags: u8 = 0b1110_0000,
    offset_high: u16 = 0,
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base: *[256]IDTEntry,
};

// Interrupt Descriptor Table.
var idt: [256]IDTEntry = [_]IDTEntry{.{}} ** 256;

var idtr = IDTRegister{
    .limit = @intCast(@sizeOf(@TypeOf(idt)) - 1),
    .base = undefined, // &idt,
};

////
// Setup an IDT entry.
//
// Arguments:
//     n: Index of the gate.
//     flags: Type and attributes.
//     offset: Address of the ISR.
//
pub fn setGate(n: u8, flags: u8, offset: fn () callconv(.C) void) void {
    const intOffset = @intFromPtr(&offset);

    idt[n].offset_low = @truncate(intOffset);
    idt[n].offset_high = @truncate(intOffset >> 16);
    idt[n].flags = flags;
    idt[n].zero = 0;
    idt[n].selector = gdt.KERNEL_CODE;
}

pub fn init() void {
    tty.printf("Setting up the Interrupt Descriptor Table", .{});
    idtr.base = &idt;

    interrupt.init();
    x86.lidt(@intFromPtr(&idtr));
    util.outb(0x20, 0xfd);
    asm volatile ("sti");
    pic.PICRemap(32, 32 + 8);

    tty.printf("[ ok ]\n", .{});
}
