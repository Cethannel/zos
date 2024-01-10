const kstd = @import("kernel_std.zig");

const GDTEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

const GDTRegister = packed struct {
    limit: u16,
    base: *const GDTEntry,
};

extern fn loadGDT(gdtr: *const GDTRegister) void;

fn create_descriptor(base: u32, limit: u32, flag: u32) void {
    var descriptor: u64 = 0;

    // Create the high 32 bit segment
    descriptor = limit & 0x000F0000; // set limit bits 19:16
    descriptor |= (flag << 8) & 0x00F0FF00; // set type, p, dpl, s, g, d/b, l and avl fields
    descriptor |= (base >> 16) & 0x000000FF; // set base bits 23:16
    descriptor |= base & 0xFF000000; // set base bits 31:24

    // Shift by 32 to allow for low part of segment
    descriptor <<= 32;

    // Create the low 32 bit segment
    descriptor |= base << 16; // set base bits 15:0
    descriptor |= limit & 0x0000FFFF; // set limit bits 15:0

    kstd.print("0x%.16llX\n", descriptor);
}

fn SEG_DESCTYPE(x: u32) u32 {
    return x << 0x04;
}

fn SEG_PRES(x: u32) u32 {
    return x << 0x07;
}

fn SEG_SAVL(x: u32) u32 {
    return x << 0x0C;
}

fn SEG_LONG(x: u32) u32 {
    return x << 0x0D;
}

fn SEG_SIZE(x: u32) u32 {
    return x << 0x0E;
}

fn SEG_GRAN(x: u32) u32 {
    return x << 0x0F;
}

fn SEG_PRIV(x: u32) u32 {
    return (x & 0x03) << 0x05;
}

const SEG_DATA_RD = 0x00; // Read-Only
const SEG_DATA_RDA = 0x01; // Read-Only, accessed
const SEG_DATA_RDWR = 0x02; // Read/Write
const SEG_DATA_RDWRA = 0x03; // Read/Write, accessed
const SEG_DATA_RDEXPD = 0x04; // Read-Only, expand-down
const SEG_DATA_RDEXPDA = 0x05; // Read-Only, expand-down, accessed
const SEG_DATA_RDWREXPD = 0x06; // Read/Write, expand-down
const SEG_DATA_RDWREXPDA = 0x07; // Read/Write, expand-down, accessed
const SEG_CODE_EX = 0x08; // Execute-Only
const SEG_CODE_EXA = 0x09; // Execute-Only, accessed
const SEG_CODE_EXRD = 0x0A; // Execute/Read
const SEG_CODE_EXRDA = 0x0B; // Execute/Read, accessed
const SEG_CODE_EXC = 0x0C; // Execute-Only, conforming
const SEG_CODE_EXCA = 0x0D; // Execute-Only, conforming, accessed
const SEG_CODE_EXRDC = 0x0E; // Execute/Read, conforming
const SEG_CODE_EXRDCA = 0x0F; // Execute/Read, conforming, accessed

const GDT_CODE_PL0 = SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) |
    SEG_LONG(0) | SEG_SIZE(1) | SEG_GRAN(1) |
    SEG_PRIV(0) | SEG_CODE_EXRD;

const GDT_DATA_PL0 = SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) |
    SEG_LONG(0) | SEG_SIZE(1) | SEG_GRAN(1) |
    SEG_PRIV(0) | SEG_DATA_RDWR;

const GDT_CODE_PL3 = SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) |
    SEG_LONG(0) | SEG_SIZE(1) | SEG_GRAN(1) |
    SEG_PRIV(3) | SEG_CODE_EXRD;

const GDT_DATA_PL3 = SEG_DESCTYPE(1) | SEG_PRES(1) | SEG_SAVL(0) |
    SEG_LONG(0) | SEG_SIZE(1) | SEG_GRAN(1) |
    SEG_PRIV(3) | SEG_DATA_RDWR;

var gdt align(4) = []GDTEntry {
    makeEntry(0, 0, 0, 0),
    makeEntry(0, 0xFFFFF, KERNEL | CODE, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, KERNEL | DATA, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, USER   | CODE, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, USER   | DATA, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0, 0, 0),  // TSS (fill in at runtime).
};

export fn gdt_init() void {
    create_descriptor(0, 0, 0);
    create_descriptor(0, 0x000FFFFF, (GDT_CODE_PL0));
    create_descriptor(0, 0x000FFFFF, (GDT_DATA_PL0));
    create_descriptor(0, 0x000FFFFF, (GDT_CODE_PL3));
    create_descriptor(0, 0x000FFFFF, (GDT_DATA_PL3));
}
