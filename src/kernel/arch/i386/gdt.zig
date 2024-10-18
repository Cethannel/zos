const kstd = @import("../../kernel_std.zig");
const Memory = @import("memory.zig");

pub const KERNEL_CODE = 0x08;
pub const KERNEL_DATA = 0x10;
pub const USER_CODE = 0x18;
pub const USER_DATA = 0x20;
pub const TSS_DESC = 0x28;

pub const KERNEL_RPL = 0b00;
pub const USER_RPL = 0b11;

const KERNEL = 0x90;
const USER = 0xF0;
const CODE = 0x0A;
const DATA = 0x02;
const TSS_ACCESS = 0x89;

const PROTECTED = (1 << 2);
const BLOCKS_4K = (1 << 3);

extern fn gdt_load(*GdtPtr) void;

const GdtPtr = packed struct {
    limit: u16,
    base: u32,
};

const GdtEntry = packed struct {
    Limit0: u16,
    Base0: u16,
    Base1: u8,
    AccessByte: u8,
    Flags: u8,
    Base2: u8,
};

const Gdt align(0x1000) = packed struct {
    null: GdtEntry, // 0x00
    kernel_code: GdtEntry, // 0x08
    kernel_data: GdtEntry, // 0x10

};

const defaultGDT align(0x1000) = Gdt{
    .null = .{
        .Limit0 = 0,
        .Base0 = 0,
        .Base1 = 0,
        .AccessByte = 0x00,
        .Flags = 0x00,
        .Base2 = 0,
    }, // null segment
    .kernel_code = .{
        .Limit0 = 0,
        .Base0 = 0,
        .Base1 = 0,
        .AccessByte = 0x9a,
        .Flags = 0xcf,
        .Base2 = 0,
    }, // kernel code
    .kernel_data = .{
        .Limit0 = 0,
        .Base0 = 0,
        .Base1 = 0,
        .AccessByte = 0x92,
        .Flags = 0xcf,
        .Base2 = 0,
    }, // kernel data
};

var GDTStruct: GdtPtr = .{
    .base = undefined,
    .limit = undefined,
};

pub fn init() void {
    //asm volatile ("cli");
    //defer asm volatile ("sti");

    GDTStruct.limit = (@sizeOf(Gdt)) - 1;
    GDTStruct.base = @intFromPtr(&defaultGDT);
    gdt_load(&GDTStruct);
}

fn createDescriptor(base: u32, limit: u32, flag: u16) void {
    var descriptor: u64 = 0;

    descriptor = limit & 0x000F0000; // set limit bits 19:16
    descriptor |= (flag << 8) & 0x00F0FF00; // set type, p, dpl, s, g, d/b, l and avl fields
    descriptor |= (base >> 16) & 0x000000FF; // set base bits 23:16
    descriptor |= base & 0xFF000000; // set base bits 31:24

    descriptor <<= 32;

    // Create the low 32 bit segment
    descriptor |= base << 16; // set base bits 15:0
    descriptor |= limit & 0x0000FFFF; // set limit bits 15:0

}
