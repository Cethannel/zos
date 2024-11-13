const util = @import("util.zig");
const x86 = @import("x86.zig");

const std = @import("std");

const PIC1 = 0x20; // IO base address for master PIC */
const PIC2 = 0xA0; // IO base address for slave PIC */
const PIC1_COMMAND = PIC1;
const PIC1_DATA = (PIC1 + 1);
const PIC2_COMMAND = PIC2;
const PIC2_DATA = (PIC2 + 1);

const PIC_EOI = 0x20; // End-of-interrupt command code */

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

pub fn sendEOI(irq: u8) void {
    if (irq >= 8)
        util.outb(PIC2_COMMAND, PIC_EOI);

    util.outb(PIC1_COMMAND, PIC_EOI);
}

pub fn PICRemap(offset1: u8, offset2: u8) void {
    const a1 = util.inb(PIC1_DATA); // save masks
    const a2 = util.inb(PIC2_DATA);

    util.outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4); // starts the initialization sequence (in cascade mode)
    x86.io_wait();
    util.outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    x86.io_wait();
    util.outb(PIC1_DATA, offset1); // ICW2: Master PIC vector offset
    x86.io_wait();
    util.outb(PIC2_DATA, offset2); // ICW2: Slave PIC vector offset
    x86.io_wait();
    util.outb(PIC1_DATA, 4); // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    x86.io_wait();
    util.outb(PIC2_DATA, 2); // ICW3: tell Slave PIC its cascade identity (0000 0010)
    x86.io_wait();

    util.outb(PIC1_DATA, ICW4_8086); // ICW4: have the PICs use 8086 mode (and not 8080 mode)
    x86.io_wait();
    util.outb(PIC2_DATA, ICW4_8086);
    x86.io_wait();

    util.outb(PIC1_DATA, a1); // restore saved masks.
    util.outb(PIC2_DATA, a2);
}
