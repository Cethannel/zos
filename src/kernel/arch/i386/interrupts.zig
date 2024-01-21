const kstd = @import("../../kernel_std.zig");

const InterruptDescriptor32 = extern struct {
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

const IDTR = extern struct {
    size: u16,
    offset: *const InterruptDescriptor32,
};

const IDT = extern struct {
    descriptors: [256]InterruptDescriptor32,
};

export fn timer_handler() callconv(.C) void {
    kstd.printf("timer interrupt\n", .{});
}

export fn key_handler() callconv(.C) void {
    kstd.printf("key interrupt\n", .{});
    while (true) {
        asm volatile ("hlt");
    }
}

var idt = IDT{
    .descriptors = [_]InterruptDescriptor32{default_descriptor} ** 256,
};

extern fn irq8() void;
extern fn irq1() void;

extern fn load_idt(idtr: *const IDTR) void;

pub fn init() void {
    idt.descriptors[0] = InterruptDescriptor32{
        .offset_1 = @intCast(@intFromPtr(&irq8) & 0xffff),
        .selector = 0x08,
        .zero = 0,
        .type_attributes = 0x8e,
        .offset_2 = @intCast(@intFromPtr(&irq8) >> 16),
    };

    idt.descriptors[1] = InterruptDescriptor32{
        .offset_1 = @intCast(@intFromPtr(&irq1) & 0xffff),
        .selector = 0x08,
        .zero = 0,
        .type_attributes = 0x8e,
        .offset_2 = @intCast(@intFromPtr(&irq1) >> 16),
    };

    const idtr = IDTR{
        .size = @as(u16, @intCast(@sizeOf(IDT))) - 1,
        .offset = &idt.descriptors[0],
    };

    load_idt(&idtr);

    outb(0x21, 0xfd);
    outb(0xa1, 0xff);
    asm volatile ("sti");
}

extern fn outb(port: u16, value: u8) void;
extern fn inb(port: u16) u8;

inline fn io_wait() void {
    outb(0x80, 0);
}

const PIC1 = 0x20;
const PIC2 = 0xA0;
const PIC1_COMMAND = PIC1;
const PIC1_DATA = (PIC1 + 1);
const PIC2_COMMAND = PIC2;
const PIC2_DATA = (PIC2 + 1);

const ICW1_ICW4 = 0x01; // Indicates that ICW4 will be present */
const ICW1_SINGLE = 0x02; // Single (cascade) mode */
const ICW1_INTERVAL4 = 0x04; // Call address interval 4 (8) */
const ICW1_LEVEL = 0x08; // Level triggered (edge) mode */
const ICW1_INIT = 0x10; // Initialization - required! */

const ICW4_8086 = 0x01; // 8086/88 (MCS-80/85) mode */
const ICW4_AUTO = 0x02; // Auto (normal) EOI */
const ICW4_BUF_SLAVE = 0x08; // Buffered mode/slave */
const ICW4_BUF_MASTER = 0x0C; // Buffered mode/master */
const ICW4_SFNM = 0x10; // Special fully nested (not) */

fn PIC_remap(offset1: i32, offset2: i32) void {
    var a1: u8 = 0;
    var a2: u8 = 0;

    a1 = inb(PIC1_DATA); // save masks
    a2 = inb(PIC2_DATA);

    outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4); // starts the initialization sequence (in cascade mode)
    io_wait();
    outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    io_wait();
    outb(PIC1_DATA, offset1); // ICW2: Master PIC vector offset
    io_wait();
    outb(PIC2_DATA, offset2); // ICW2: Slave PIC vector offset
    io_wait();
    outb(PIC1_DATA, 4); // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    io_wait();
    outb(PIC2_DATA, 2); // ICW3: tell Slave PIC its cascade identity (0000 0010)
    io_wait();

    outb(PIC1_DATA, ICW4_8086); // ICW4: have the PICs use 8086 mode (and not 8080 mode)
    io_wait();
    outb(PIC2_DATA, ICW4_8086);
    io_wait();

    outb(PIC1_DATA, a1); // restore saved masks.
    outb(PIC2_DATA, a2);
}
