const kstd = @import("../../kernel_std.zig");
const InterruptRegisters = @import("util.zig").InterruptRegisters;

const outb = @import("util.zig").outb;

const InterruptDescriptor32 = packed struct {
    offset_1: u16, // offset bits 0..15
    selector: u16, // a code segment selector in GDT or LDT
    zero: u8, // unused, set to 0
    type_attributes: u8, // gate type, dpl, and p fields
    offset_2: u16, // offset bits 16..31
};

const default_descriptor = InterruptDescriptor32{
    .offset_1 = 0,
    .selector = 0,
    .zero = 0,
    .type_attributes = 0,
    .offset_2 = 0,
};

const IDTR = packed struct {
    size: u16,
    offset: u32,
};

extern fn isr0() void;
extern fn isr1() void;
extern fn isr2() void;
extern fn isr3() void;
extern fn isr4() void;
extern fn isr5() void;
extern fn isr6() void;
extern fn isr7() void;
extern fn isr8() void;
extern fn isr9() void;
extern fn isr10() void;
extern fn isr11() void;
extern fn isr12() void;
extern fn isr13() void;
extern fn isr14() void;
extern fn isr15() void;
extern fn isr16() void;
extern fn isr17() void;
extern fn isr18() void;
extern fn isr19() void;
extern fn isr20() void;
extern fn isr21() void;
extern fn isr22() void;
extern fn isr23() void;
extern fn isr24() void;
extern fn isr25() void;
extern fn isr26() void;
extern fn isr27() void;
extern fn isr28() void;
extern fn isr29() void;
extern fn isr30() void;
extern fn isr31() void;

extern fn irq0() void;
extern fn irq1() void;
extern fn irq2() void;
extern fn irq3() void;
extern fn irq4() void;
extern fn irq5() void;
extern fn irq6() void;
extern fn irq7() void;
extern fn irq8() void;
extern fn irq9() void;
extern fn irq10() void;
extern fn irq11() void;
extern fn irq12() void;
extern fn irq13() void;
extern fn irq14() void;
extern fn irq15() void;

extern fn isr128() void;
extern fn isr177() void;

var idt_entries = [_]InterruptDescriptor32{default_descriptor} ** 256;
var idt_ptr = IDTR{
    .size = 0,
    .offset = 0,
};

extern fn idt_flush(thing: u32) void;

pub fn new_init() void {
    idt_ptr.size = @sizeOf(InterruptDescriptor32) * 256 - 1;
    idt_ptr.offset = @intCast(@intFromPtr(&idt_entries));

    outb(0x20, 0x11);
    outb(0xA0, 0x11);

    outb(0x21, 0x20);
    outb(0xA1, 0x28);

    outb(0x21, 0x04);
    outb(0xA1, 0x02);

    outb(0x21, 0x01);
    outb(0xA1, 0x01);

    outb(0x21, 0x0);
    outb(0xA1, 0x0);

    setIdtGate(0, @intFromPtr(&isr0), 0x08, 0x8E);
    setIdtGate(1, @intFromPtr(&isr1), 0x08, 0x8E);
    setIdtGate(2, @intFromPtr(&isr2), 0x08, 0x8E);
    setIdtGate(3, @intFromPtr(&isr3), 0x08, 0x8E);
    setIdtGate(4, @intFromPtr(&isr4), 0x08, 0x8E);
    setIdtGate(5, @intFromPtr(&isr5), 0x08, 0x8E);
    setIdtGate(6, @intFromPtr(&isr6), 0x08, 0x8E);
    setIdtGate(7, @intFromPtr(&isr7), 0x08, 0x8E);
    setIdtGate(8, @intFromPtr(&isr8), 0x08, 0x8E);
    setIdtGate(9, @intFromPtr(&isr9), 0x08, 0x8E);
    setIdtGate(10, @intFromPtr(&isr10), 0x08, 0x8E);
    setIdtGate(11, @intFromPtr(&isr11), 0x08, 0x8E);
    setIdtGate(12, @intFromPtr(&isr12), 0x08, 0x8E);
    setIdtGate(13, @intFromPtr(&isr13), 0x08, 0x8E);
    setIdtGate(14, @intFromPtr(&isr14), 0x08, 0x8E);
    setIdtGate(15, @intFromPtr(&isr15), 0x08, 0x8E);
    setIdtGate(16, @intFromPtr(&isr16), 0x08, 0x8E);
    setIdtGate(17, @intFromPtr(&isr17), 0x08, 0x8E);
    setIdtGate(18, @intFromPtr(&isr18), 0x08, 0x8E);
    setIdtGate(19, @intFromPtr(&isr19), 0x08, 0x8E);
    setIdtGate(20, @intFromPtr(&isr20), 0x08, 0x8E);
    setIdtGate(21, @intFromPtr(&isr21), 0x08, 0x8E);
    setIdtGate(22, @intFromPtr(&isr22), 0x08, 0x8E);
    setIdtGate(23, @intFromPtr(&isr23), 0x08, 0x8E);
    setIdtGate(24, @intFromPtr(&isr24), 0x08, 0x8E);
    setIdtGate(25, @intFromPtr(&isr25), 0x08, 0x8E);
    setIdtGate(26, @intFromPtr(&isr26), 0x08, 0x8E);
    setIdtGate(27, @intFromPtr(&isr27), 0x08, 0x8E);
    setIdtGate(28, @intFromPtr(&isr28), 0x08, 0x8E);
    setIdtGate(29, @intFromPtr(&isr29), 0x08, 0x8E);
    setIdtGate(30, @intFromPtr(&isr30), 0x08, 0x8E);
    setIdtGate(31, @intFromPtr(&isr31), 0x08, 0x8E);

    setIdtGate(32, @intFromPtr(&irq0), 0x08, 0x8E);
    setIdtGate(33, @intFromPtr(&irq1), 0x08, 0x8E);
    setIdtGate(34, @intFromPtr(&irq2), 0x08, 0x8E);
    setIdtGate(35, @intFromPtr(&irq3), 0x08, 0x8E);
    setIdtGate(36, @intFromPtr(&irq4), 0x08, 0x8E);
    setIdtGate(37, @intFromPtr(&irq5), 0x08, 0x8E);
    setIdtGate(38, @intFromPtr(&irq6), 0x08, 0x8E);
    setIdtGate(39, @intFromPtr(&irq7), 0x08, 0x8E);
    setIdtGate(40, @intFromPtr(&irq8), 0x08, 0x8E);
    setIdtGate(41, @intFromPtr(&irq9), 0x08, 0x8E);
    setIdtGate(42, @intFromPtr(&irq10), 0x08, 0x8E);
    setIdtGate(43, @intFromPtr(&irq11), 0x08, 0x8E);
    setIdtGate(44, @intFromPtr(&irq12), 0x08, 0x8E);
    setIdtGate(45, @intFromPtr(&irq13), 0x08, 0x8E);
    setIdtGate(46, @intFromPtr(&irq14), 0x08, 0x8E);
    setIdtGate(47, @intFromPtr(&irq15), 0x08, 0x8E);

    setIdtGate(128, @intFromPtr(&isr128), 0x08, 0x8E);
    setIdtGate(177, @intFromPtr(&isr177), 0x08, 0x8E);

    idt_flush(@intCast(@intFromPtr(&idt_ptr)));
}

pub fn setIdtGate(num: u8, base: u32, sel: u16, flags: u8) void {
    idt_entries[num].offset_1 = @intCast(base & 0xFFFF);
    idt_entries[num].offset_2 = @intCast((base >> 16) & 0xFFFF);
    idt_entries[num].selector = sel;
    idt_entries[num].zero = 0;
    idt_entries[num].type_attributes = flags | 0x60;
}

// TODO: Fix divide by zero
export fn isr_handler(regs: *InterruptRegisters) void {
    if (regs.int_no < 32) {
        kstd.printf("received interrupt: {s}\n", .{exception_messages[regs.int_no]});
        kstd.printf("Exception. System Halted!\n", .{});
        while (true) {
            //asm volatile ("hlt");
        }
    }
}

fn default_irq_handler(regs: *InterruptRegisters) void {
    kstd.printf("received irq: {}\n", .{regs.int_no});
}

var irq_routines = [_]u32{0} ** 16;

pub fn irq_install_handler(irq: u8, handler: *const fn (regs: *InterruptRegisters) void) void {
    irq_routines[irq] = @intFromPtr(handler);
}

pub fn irq_uninstall_handler(irq: u8) void {
    irq_routines[irq] = 0;
}

export fn irq_handler(regs: *InterruptRegisters) void {
    var handler = irq_routines[regs.int_no - 32];
    if (handler != 0) {
        var handler_fn: *fn (regs: *InterruptRegisters) void = @ptrFromInt(handler);
        handler_fn(regs);
    }

    if (regs.int_no >= 40) {
        outb(0xA0, 0x20);
    }

    outb(0x20, 0x20);
}

const exception_messages = [_][]const u8{ "Division By Zero", "Debug", "Non Maskable Interrupt", "Breakpoint", "Into Detected Overflow", "Out of Bounds", "Invalid Opcode", "No Coprocessor", "Double fault", "Coprocessor Segment Overrun", "Bad TSS", "Segment not present", "Stack fault", "General protection fault", "Page fault", "Unknown Interrupt", "Coprocessor Fault", "Alignment Fault", "Machine Check", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved", "Reserved" };
