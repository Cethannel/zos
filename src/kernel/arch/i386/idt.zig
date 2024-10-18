const gdt = @import("gdt.zig");
const interrupt = @import("interrupts.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");

pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE = 0xEE;

// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_low: u16,
    selector: u16,
    zero: u8,
    flags: u8,
    offset_high: u16,
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base: *[256]IDTEntry,
};

// Interrupt Descriptor Table.
var idt: [256]IDTEntry = undefined;

var idtr = IDTRegister{
    .limit = @intCast(@sizeOf(@TypeOf(idt))),
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
pub fn setGate(n: u8, flags: u8, offset: fn () void) void {
    const intOffset = @intFromPtr(offset);

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

    tty.printf("[ ok ]\n", .{});
}
