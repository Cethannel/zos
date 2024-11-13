const gdt = @import("gdt.zig");
const interrupt = @import("interrupts.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const util = @import("util.zig");
const pic = @import("pic.zig");

pub const InterruptRegisters = extern struct {
    cr2: u32 = @import("std").mem.zeroes(u32),
    ds: u32 = @import("std").mem.zeroes(u32),
    edi: u32 = @import("std").mem.zeroes(u32),
    esi: u32 = @import("std").mem.zeroes(u32),
    ebp: u32 = @import("std").mem.zeroes(u32),
    esp: u32 = @import("std").mem.zeroes(u32),
    ebx: u32 = @import("std").mem.zeroes(u32),
    edx: u32 = @import("std").mem.zeroes(u32),
    ecx: u32 = @import("std").mem.zeroes(u32),
    eax: u32 = @import("std").mem.zeroes(u32),
    int_no: u32 = @import("std").mem.zeroes(u32),
    err_code: u32 = @import("std").mem.zeroes(u32),
    eip: u32 = @import("std").mem.zeroes(u32),
    csm: u32 = @import("std").mem.zeroes(u32),
    eflags: u32 = @import("std").mem.zeroes(u32),
    useresp: u32 = @import("std").mem.zeroes(u32),
    ss: u32 = @import("std").mem.zeroes(u32),
};

const idtEntry = packed struct {
    base_low: u16,
    sel: u16,
    always0: u8 = 0,
    flags: u8,
    base_high: u16,
};

const idtPtr = packed struct {
    limit: u16,
    base: usize,
};

var idt_entries: [256]idtEntry = undefined;
var idt_ptr: idtPtr = undefined;

extern fn idt_flush(usize) void;

pub fn init() void {
    idt_ptr.limit = @sizeOf(idtEntry) * 256 - 1;
    idt_ptr.base = @intFromPtr(&idt_entries);

    @memset(&idt_entries, @bitCast(idtEntry{
        .flags = 0,
        .base_low = 0,
        .sel = 0,
        .always0 = 0,
        .base_high = 0,
    }));

    x86.outb(0x20, 0x11);
    x86.outb(0xA0, 0x11);

    x86.outb(0x21, 0x20);
    x86.outb(0xA1, 0x28);

    x86.outb(0x21, 0x04);
    x86.outb(0xA1, 0x02);

    x86.outb(0x21, 0x01);
    x86.outb(0xA1, 0x01);

    x86.outb(0x21, 0x0);
    x86.outb(0xA1, 0x0);

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

    setIdtGate(128, @intFromPtr(&isr128), 0x08, 0x8E); //System calls
    setIdtGate(177, @intFromPtr(&isr177), 0x08, 0x8E); //System calls

    idt_flush(@intFromPtr(&idt_ptr));
    //x86.lidt(@intFromPtr(&idt_ptr));
    //asm volatile ("sti");
}

fn setIdtGate(num: u8, base: usize, sel: u16, flags: u8) void {
    idt_entries[num].base_low = @as(u16, @bitCast(@as(c_ushort, @truncate(base & @as(u32, @bitCast(@as(c_int, 65535)))))));
    idt_entries[num].base_high = @as(u16, @bitCast(@as(c_ushort, @truncate((base >> @intCast(16)) & @as(u32, @bitCast(@as(c_int, 65535)))))));
    idt_entries[num].sel = sel;
    idt_entries[num].always0 = 0;
    idt_entries[num].flags = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, flags))) | @as(c_int, 96)))));
}

pub const exception_messages = [_][]const u8{
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment not present",
    "Stack fault",
    "General protection fault",
    "Page fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Fault",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
};

export fn isr_handler(regs: *InterruptRegisters) void {
    if (regs.int_no < 32) {
        tty.terminal_write(exception_messages[regs.int_no]);
        tty.terminal_write("\n");
        tty.terminal_write("Exception! System halted\n");
        x86.hang();
    }
}

pub const irqHandler = fn (*InterruptRegisters) void;

var irq_routines: [16]?*const irqHandler = .{null} ** 16;

pub fn irq_install_handler(irq: usize, r: irqHandler) void {
    irq_routines[irq] = r;
}

pub fn irq_uninstall_handler(irq: usize) void {
    irq_routines[irq] = null;
}

export fn irq_handler(regs: *InterruptRegisters) callconv(.C) void {
    if (regs.int_no < 32 + 16) {
        const handler = irq_routines[regs.int_no - 32];

        if (handler) |hand| {
            hand(regs);
        }
    }

    if (regs.int_no >= 40) {
        x86.outb(0xA0, 0x20);
    }

    x86.outb(0x20, 0x20);
}

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

extern fn isr128() void;
extern fn isr177() void;

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
